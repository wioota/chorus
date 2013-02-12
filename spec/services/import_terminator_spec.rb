require 'spec_helper'

describe ImportTerminator, :greenplum_integration do
  let(:instance_account) { GreenplumIntegration.real_account }
  let(:user) { instance_account.owner }
  let(:database) { GpdbDatabase.find_by_name_and_data_source_id(GreenplumIntegration.database_name, GreenplumIntegration.real_data_source) }
  let(:schema_name) { 'test_schema' }
  let(:schema) { database.schemas.find_by_name(schema_name) }

  before do
    execute(destination_database_url, "drop table if exists #{destination_table_fullname};")
    dir = Pathname.new ChorusConfig.instance['gpfdist.data_dir']
  end

  describe '#terminate' do
    let(:source_dataset) { schema.datasets.find_by_name("base_table1") }

    let(:workspace) do
      ws = workspaces(:public)
      ws.sandbox = schema
      ws.save!
      ws
    end

    let(:sandbox) { workspace.sandbox }
    let(:destination_table_name) { "forever_table" }
    let(:destination_table_fullname) { %Q{"#{sandbox.name}"."#{destination_table_name}"}}
    let(:destination_database_url) { database.connect_with(instance_account).db_url }

    let!(:import) do
      FactoryGirl.create :import, {
          :to_table => destination_table_name,
          :user => user,
          :workspace => workspace,
          :source_dataset => source_dataset
      }
    end

    def log_for
      log_text = ""
      stub(ImportTerminator).log.with_any_args do |text|
        log_text << text << "\n"
      end
      yield
      log_text
    end

    context "with a real GpPipe job" do
      def stub_reader_sql
        any_instance_of(GpPipe) do |pipe|
          stub.proxy(pipe).reader_sql do |sql|
            "SELECT pg_sleep(300) /* #{sql} */"
          end
        end
      end

      def stub_writer_sql
        any_instance_of(GpPipe) do |pipe|
          stub.proxy(pipe).writer_sql do |sql|
            "SELECT pg_sleep(300) /* #{sql} */"
          end
        end
      end

      let(:import_manager) { ImportManager.new(import) }

      context "when both reader and writer pipes are stuck" do
        before do
          any_instance_of(GpTableCopier) do |copier|
            stub(copier).use_gp_pipe? { true }
          end
          stub_writer_sql
          stub_reader_sql
          @runner = Thread.new do
            begin
            # stub reload in new thread because import isn't really persisted due to transactional rspec
            stub(import).reload { import }
            ImportExecutor.new(import).run
            rescue Sequel::DatabaseError
            end
          end
          until import_manager.busy?(:writer) && import_manager.busy?(:reader)
            sleep 0.1
          end
        end

        after do
          @runner.join(5).should(be_true) if @runner
          execute(destination_database_url, "drop table if exists #{destination_table_fullname};")
        end

        it "removes the named pipe" do
          import_manager.named_pipe.should_not be_nil
          expect(log_for {
            ImportTerminator.terminate(import)
          }).to match /named pipe/
          import_manager.named_pipe.should be_nil
        end

        it "kills the reader" do
          expect(log_for {
            ImportTerminator.terminate(import)
          }).to match /Found running reader/
        end

        it "kills the writer" do
          expect(log_for {
            ImportTerminator.terminate(import)
          }).to match /Found running writer/
        end
      end

    end

    def execute(database, sql_command, schema = schema, method = :run)
      with_database_connection(database) do |connection|
        connection.run("set search_path to #{schema.name}, public;")
        connection.send(method, sql_command)
      end
    end

    def with_database_connection(database, &block)
      if database.is_a?(String)
        Sequel.connect(database, {}, &block)
      else
        block.call database
      end
    rescue Exception
      raise
    end
  end

end