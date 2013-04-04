require 'spec_helper'

describe GpdbSchema do
  describe "associations" do
    it { should belong_to(:parent) }
    it { should have_many(:datasets) }
    it { should have_many(:workspaces) }
    it { should have_many(:imports) }

    describe "#database" do
      let(:schema) {
         GpdbSchema.create!(:name => 'test_schema', :database => gpdb_databases(:default))
      }

      it "returns the schemas parent" do
        schema.reload.database.should == gpdb_databases(:default)
      end
    end

    describe 'validations' do
      it 'has a valid factory' do
        FactoryGirl.build(:gpdb_schema).should be_valid
      end

      it { should validate_presence_of(:name) }

      it 'does not allow slashes, ampersands and question marks' do
        ['/', '&', '?'].each do |char|
          new_schema = FactoryGirl.build(:gpdb_schema, :name => "schema#{char}name")
          new_schema.should_not be_valid
          new_schema.should have_error_on(:name)
        end
      end

      describe 'name uniqueness' do
        let(:existing) { schemas(:default) }

        context 'in the same db' do
          it 'does not allow two databases with the same name' do
            new_schema = FactoryGirl.build(:gpdb_schema,
                                           :name => existing.name,
                                           :database => existing.database)
            new_schema.should_not be_valid
            new_schema.should have_error_on(:name).with_message(:taken)
          end
        end

        context 'in a different db' do
          it 'allows same names' do
            new_schema = FactoryGirl.build(:gpdb_schema,
                                           :name => existing.name)
            new_schema.should be_valid
          end
        end
      end
    end

    describe "cascading deletes" do
      it "deletes its datasets when it is destroyed" do
        schema = schemas(:default)

        expect {
          schema.destroy
        }.to change(schema.datasets, :count).to(0)
      end

      it "nullifies its sandbox association in workspaces" do
        schema = schemas(:searchquery_schema)
        workspace = FactoryGirl.create(:workspace, :sandbox => schema)

        expect {
          expect {
            schema.destroy
          }.to change(Workspace, :count).by(0)
        }.to change { workspace.reload.sandbox }.from(schema).to(nil)
      end
    end
  end

  describe '#accessible_to' do
    let(:gpdb_data_source) { data_sources(:owners) }
    let(:account) { gpdb_data_source.owner_account }
    let(:schema) { schemas(:default) }

    it 'returns true if the user can access the gpdb instance' do
      owner = account.owner
      any_instance_of(GpdbDataSource) do |instance|
        mock(instance).accessible_to(owner) { true }
      end

      schema.accessible_to(owner).should be_true
    end
  end

  it_behaves_like 'a subclass of schema' do
    let(:schema) { schemas(:default) }
  end

  context "refresh returns the list of schemas", :greenplum_integration do
    let(:account) { GreenplumIntegration.real_account }
    let(:database) { GpdbDatabase.find_by_name(GreenplumIntegration.database_name) }

    it "returns the sorted list of schemas" do
      schemas = GpdbSchema.refresh(account, database)
      schemas.should be_a(Array)
      schemas.map(&:name).sort.should == schemas.map(&:name).sort
    end
  end

  describe "#stored_functions" do
    let(:schema) { schemas(:public) }
    let(:account) { schema.database.data_source.owner_account }
    let(:connection) { Object.new }

    before do
      stub(schema).connect_with(account) { connection }
      stub(connection).functions do
        [
            {:oid => 62792, :proname => "funky_town", :lanname => "sql", :rettype => "text", :proargnames => ["i"], :argtypes => "int4", :prosrc => " SELECT CAST($1 AS text) || ' is text' ", :description => "comment on funky_town"},
            {:oid => 62793, :proname => "towny_funk", :lanname => "sql", :rettype => "record", :proargnames => ["i", "foo", "bar"], :argtypes => "int4", :prosrc => " SELECT $1, CAST($1 AS text) || ' is text' ", :description => nil},
            {:oid => 63121, :proname => "multi_arg_function", :lanname => "sql", :rettype => "int4", :proargnames => ["i", "j", "k"], :argtypes => "float8", :prosrc => "select 1", :description => "comment on multi_arg"},
            {:oid => 63121, :proname => "multi_arg_function", :lanname => "sql", :rettype => "int4", :proargnames => ["i", "j", "k"], :argtypes => "varchar", :prosrc => "select 1", :description => "comment on multi_arg"},
            {:oid => 63121, :proname => "multi_arg_function", :lanname => "sql", :rettype => "int4", :proargnames => ["i", "j", "k"], :argtypes => "int4", :prosrc => "select 1", :description => "comment on multi_arg"}
          ]
      end
    end

    it "returns the GpdbSchemaFunctions" do
      functions = schema.stored_functions(account)

      functions.count.should == 3

      last_function = functions.last
      last_function.should be_a GpdbSchemaFunction
      last_function.schema_name.should == schema.name
      last_function.function_name.should == "multi_arg_function"
      last_function.language.should == "sql"
      last_function.return_type.should == "int4"
      last_function.arg_names.should == ["i", "j", "k"]
      last_function.arg_types.should == ["float8", "varchar", "int4"]
      last_function.definition.should == "select 1"
      last_function.description.should == "comment on multi_arg"
    end
  end

  describe "#disk_space_used" do
    let(:schema) { schemas(:default) }
    let(:account) { instance_accounts(:unauthorized) }
    let(:connection) { Object.new }
    let(:disk_space_used) { 12345 }

    before do
      stub(schema).connect_with(account) { connection }
      mock(connection).disk_space_used { disk_space_used }
    end

    it "returns the disk space used by all relations in the schema" do
      schema.disk_space_used(account).should == 12345
    end

    it "caches the value" do
      schema.disk_space_used(account).should == 12345
      schema.disk_space_used(account).should == 12345
    end

    context "when we can't calculate the size" do
      let(:disk_space_used) { raise Exception }

      it "should return nil" do
        schema.disk_space_used(account).should be_nil
      end

      it "should cache the value correctly" do
        schema.disk_space_used(account).should be_nil
        schema.disk_space_used(account).should be_nil
      end
    end
  end

  describe "callbacks" do
    let(:schema) { schemas(:default) }

    describe "before_save" do
      describe "#mark_datasets_as_stale" do
        it "if the schema has become stale, datasets will also be marked as stale" do
          schema.mark_stale!
          dataset = schema.datasets.views_tables.first
          dataset.should be_stale
          dataset.stale_at.should be_within(5.seconds).of(Time.current)
        end
      end
    end
  end

  describe "#connect_with" do
    let(:schema) { schemas(:public) }
    let(:account) { instance_accounts(:unauthorized) }
    let(:mockConnection) { {} }

    before do
      mock(GreenplumConnection).new({
                                        :host => schema.data_source.host,
                                        :port => schema.data_source.port,
                                        :username => account.db_username,
                                        :password => account.db_password,
                                        :database => schema.database.name,
                                        :schema => schema.name,
                                        :logger => Rails.logger
                                    }) {
        mockConnection
      }
    end

    it "should create a Greenplum SchemaConnection" do
      schema.connect_with(account)
    end

    it "passes a connected connection a block" do
      stub(mockConnection).with_connection.yields(mockConnection)
      expect {
        schema.connect_with(account) do |connection|
          connection.should == mockConnection
          throw :ran_block
        end
      }.to throw_symbol :ran_block
    end
  end

  describe '#active_tables_and_views' do
    let(:schema) { schemas(:default) }

    it 'does not include chorus views' do
      cv = nil
      expect {
        cv = FactoryGirl.create(:chorus_view, :schema => schema)
      }.not_to change { schema.reload.active_tables_and_views.size }
      schema.active_tables_and_views.should_not include(cv)
    end

    it 'includes tables' do
      table = nil
      expect {
        table = FactoryGirl.create(:gpdb_table, :schema => schema)
      }.to change { schema.reload.active_tables_and_views.size }.by(1)
      schema.active_tables_and_views.should include(table)

      expect {
        table.mark_stale!
      }.to change { schema.reload.active_tables_and_views.size }.by(-1)
      schema.active_tables_and_views.should_not include(table)
    end

    it 'includes views' do
      view = nil

      expect {
        view = FactoryGirl.create(:gpdb_view, :schema => schema)
      }.to change { schema.reload.active_tables_and_views.size }.by(1)
      schema.active_tables_and_views.should include(view)

      expect {
        view.mark_stale!
      }.to change { schema.reload.active_tables_and_views.size }.by(-1)
      schema.active_tables_and_views.should_not include(view)
    end
  end

  describe "#destroy" do
    let(:schema) { schemas(:default) }

    it "should not delete the schema entry" do
      schema.destroy
      expect {
        schema.reload
      }.to_not raise_error(Exception)
    end

    it "should update the deleted_at field" do
      schema.destroy
      schema.reload.deleted_at.should_not be_nil
    end

    it "destroys dependent datasets" do
      datasets = schema.datasets
      datasets.length.should > 0

      schema.destroy
      datasets.each do |dataset|
        Dataset.find_by_id(dataset.id).should be_nil
      end
    end

    it "removes any sandboxes from associated workspaces" do
      workspaces = schema.workspaces
      workspaces.length.should > 0

      schema.destroy
      workspaces.each do |workspace|
        workspace.reload.sandbox_id.should be_nil
      end
    end

    it "removes any execution schemas from associated workfiles" do
      workfiles = schema.workfiles_as_execution_schema
      workfiles.length.should > 0

      schema.destroy
      workfiles.each do |workfile|
        workfile.reload.execution_schema_id.should be_nil
      end
    end
  end

  describe "#class_for_type" do
    let(:schema) { schemas(:default) }
    it "should return GpdbTable and GpdbView correctly" do
      schema.class_for_type('r').should == GpdbTable
      schema.class_for_type('v').should == GpdbView
    end
  end

  it_behaves_like 'a soft deletable model' do
    let(:model) { schemas(:default)}
  end
end
