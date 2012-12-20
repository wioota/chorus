require 'spec_helper'

describe ImportTerminator, :database_integration do
  let(:instance_account) { InstanceIntegration.real_gpdb_account }
  let(:user) { instance_account.owner }
  let(:database) { GpdbDatabase.find_by_name_and_gpdb_instance_id(InstanceIntegration.database_name, InstanceIntegration.real_gpdb_instance) }
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
    let(:destination_database_url) { Gpdb::ConnectionBuilder.url(database, instance_account) }

    let!(:import) do
      FactoryGirl.create :import, {
          :to_table => destination_table_name,
          :user => user,
          :workspace => workspace,
          :source_dataset => source_dataset
      }
    end

    def expect_to_log(regex)
      found = false
      stub(ImportTerminator).log.with_any_args do |text|
        found = true if text =~ regex
      end
      yield
      found.should be_true, "#{regex} not found in log"
    end

    context "when the import hasn't been started" do
      it "removes the import from the work queue" do
        expect_to_log /unstarted/ do
          QC.default_queue.enqueue("ImportExecuter.run", import.id)
          ImportTerminator.terminate(import)
          # TODO #41244423: figure out how to remove job from queue classic
          #QC.default_queue.job_count("ImportExecuter.run", import.id).should be_zero
        end
      end
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
            ImportExecutor.new(import).run
            rescue Sequel::DatabaseError
            rescue => e
              p e
              raise
            end
          end
          while import_manager.writer_procpid.nil? || import_manager.reader_procpid.nil?
            sleep 0.1
          end
        end

        after do
          @runner.join(5).should(be_true) if @runner
          execute(destination_database_url, "drop table if exists #{destination_table_fullname};")
        end

        it "removes the named pipe" do
          import_manager.named_pipe.should_not be_nil
          expect_to_log /named pipe/ do
            ImportTerminator.terminate(import)
          end
          import_manager.named_pipe.should be_nil
        end

        it "kills the reader" do
          expect_to_log /Found running reader/ do
            ImportTerminator.terminate(import)
          end
        end

        it "kills the writer" do
          expect_to_log /Found running writer/ do
            ImportTerminator.terminate(import)
          end
        end

        it "allows the chorus worker to finish" do
          ImportTerminator.terminate(import)
          @runner.join(5).should_not be_nil
          @runner = nil
        end
      end

    end

    def execute(database, sql_command, schema = schema, method = :run)
      with_database_connection(database) do |connection|
        connection.run("set search_path to #{schema.name}, public;")
        connection.send(method, sql_command)
      end
    end
    #
    #def get_rows(database, sql_command, schema = schema)
    #  execute(database, sql_command, schema, :fetch).all
    #end

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