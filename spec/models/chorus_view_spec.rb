require "spec_helper"

describe ChorusView do
  describe "validations" do
    it "validates presence of workspace_id" do
      chorus_view = ChorusView.new
      chorus_view.should have_at_least(1).error_on(:workspace_id)
    end

    it "validates presence of query" do
      chorus_view = ChorusView.new
      chorus_view.should have_at_least(1).error_on(:query)
    end

    it "validates presence of schema_id" do
      chorus_view = ChorusView.new
      chorus_view.should have_at_least(1).error_on(:schema_id)
    end

    describe "#validate_query", :database_integration => true do
      let(:database) { InstanceIntegration.real_database }
      let(:schema) { database.schemas.find_by_name('public') }
      let(:account) { InstanceIntegration.real_gpdb_account }
      let(:gpdb_instance) { InstanceIntegration.real_gpdb_instance }
      let(:workspace) { workspaces(:public)}
      let(:user) { users(:the_collaborator) }
      let(:chorus_view) { FactoryGirl.build(:chorus_view, :schema => schema, :query => query, :workspace => workspace) }
      before do
        set_current_user(user)
      end

      let(:query) { "selecT 1;" }

      it "runs as current_user" do
        mock(schema).with_gpdb_connection(gpdb_instance.account_for_user!(user), true)
        chorus_view.valid?
      end

      it "can be valid" do
        chorus_view.should be_valid
      end

      describe 'with multiple statements' do
        let(:query) {  "select 1; create table nonexistent();" }

        it 'is invalid' do
          chorus_view.should_not be_valid
          chorus_view.errors[:query][0][0].should == :multiple_result_sets
        end

        it 'cleans up' do
          chorus_view.validate_query
          schema.with_gpdb_connection(account) do |conn|
            expect {
              conn.exec_query("select * from nonexistent")
            }.to raise_error(ActiveRecord::StatementInvalid)
          end
        end
      end

      it 'is invalid if it references a nonexistent table' do
        chorus_view = FactoryGirl.build(:chorus_view,
                                        :workspace => workspace,
                                        :schema => schema,
                                        :query => "select * from a_non_existent_table_aaa;")
        chorus_view.should_not be_valid
        chorus_view.errors[:query][0][0].should == :generic
      end

      it 'is invalid if it doesnt start with select or with' do
        chorus_view = FactoryGirl.build(:chorus_view,
                                           :schema => schema,
                                           :workspace => workspace,
                                           :query => "create table query_not_starting_with_keyword_table();")
        chorus_view.should_not be_valid
        chorus_view.errors[:query][0][0].should == :start_with_keywords
      end
    end
  end

  describe "update" do
    let(:chorus_view) { datasets(:chorus_view) }

    it "prevents schema from being updated" do
      new_schema = gpdb_schemas(:public)
      chorus_view.schema.should_not == new_schema
      chorus_view.schema = new_schema
      chorus_view.schema_id = new_schema.id
      chorus_view.save!
      chorus_view.reload
      chorus_view.schema.should_not == new_schema
    end

    it "prevents workspace from being updated" do
      new_workspace = workspaces(:public_with_no_collaborators)
      chorus_view.workspace.should_not == new_workspace
      chorus_view.workspace = new_workspace
      chorus_view.workspace_id = new_workspace.id
      chorus_view.save!
      chorus_view.reload
      chorus_view.workspace.should_not == new_workspace
    end
  end

  describe "#preview_sql" do
    let(:chorus_view) do
      ChorusView.new({:name => "query",
                      :schema => gpdb_schemas(:default),
                      :query => "select 1"},
                     :without_protection => true)
    end

    it "returns the query" do
      chorus_view.preview_sql.should == "select 1"
    end
  end

  describe "#all_row_sql" do
    let(:chorus_view) do
      ChorusView.new({:name => "query",
                      :schema => gpdb_schemas(:default),
                      :query => "select 1"},
                     :without_protection => true)
    end

    it "returns the correct sql" do
      chorus_view.all_rows_sql().strip.should == %Q{SELECT * FROM (select 1) AS cv_query}
    end

    it "returns the sql without semicolon" do
      chorus_view.query = "select 2;"
      chorus_view.all_rows_sql().strip.should == %Q{SELECT * FROM (select 2) AS cv_query}
    end

    context "with a limit" do
      it "uses the limit" do
        chorus_view.all_rows_sql(10).should match "LIMIT 10"
      end
    end
  end

  describe "#convert_to_database_view", :database_integration => true do
    let(:chorus_view) { FactoryGirl.build(:chorus_view, :schema => schema, :query => "select 1") }
    let(:database) { InstanceIntegration.real_database }
    let(:gpdb_instance) { InstanceIntegration.real_gpdb_instance }
    let(:schema) { database.schemas.find_by_name('test_schema') }
    let(:account) { gpdb_instance.owner_account }
    let(:user) { account.owner }

    before do
      Gpdb::ConnectionBuilder.connect!(gpdb_instance, account, database.name) do |connection|
        connection.exec_query("DROP VIEW IF EXISTS \"test_schema\".\"henry\"")
      end
    end

    it "creates a database view" do
      expect {
        chorus_view.convert_to_database_view("henry", user)
      }.to change(GpdbView, :count).by(1)
    end

    it "sets the right query" do
      chorus_view.convert_to_database_view("henry", user)
      GpdbView.last.query.should == chorus_view.query
      GpdbView.last.name.should == "henry"
    end

    it "creates the view in greenplum db" do
      chorus_view.convert_to_database_view("henry", user)
      Gpdb::ConnectionBuilder.connect!(gpdb_instance, account, database.name) do |connection|
        connection.exec_query("SELECT viewname FROM pg_views WHERE viewname = 'henry'").should_not be_empty
      end
    end

    it "doesn't create the view twice" do
      chorus_view.convert_to_database_view("henry", user)
      expect {
        chorus_view.convert_to_database_view("henry", user)
      }.to raise_error(Gpdb::ViewAlreadyExists)
    end

    it "throws an exception if it can't create the view" do
      any_instance_of(::ActiveRecord::ConnectionAdapters::JdbcAdapter) do |conn|
        stub(conn).exec_query { raise ActiveRecord::StatementInvalid }
      end

      expect {
        chorus_view.convert_to_database_view("henry", user)
      }.to raise_error(Gpdb::CantCreateView)
    end

    context "#check_duplicate_column" do
      let(:chorus_view) { FactoryGirl.build(:chorus_view, :schema => schema, :query => "select 1, 3;") }

      it "should throws error when there's duplicate column names" do
        expect {
          chorus_view.check_duplicate_column(user)
        }.to raise_error
      end
    end
  end

  describe '#add_metadata!(account)', :database_integration => true do
    let(:schema) { database.schemas.find_by_name('test_schema') }
    let(:database) { InstanceIntegration.real_database }
    let(:chorus_view) { FactoryGirl.build(:chorus_view, :schema => schema, :query => "select 1, 2, 3, 4, 5") }
    let(:gpdb_instance) { InstanceIntegration.real_gpdb_instance }
    let(:account) { gpdb_instance.owner_account }

    it "retrieves the statistics" do
      chorus_view.add_metadata!(account)
      chorus_view.statistics.column_count.should == 5
    end
  end
end