require "spec_helper"

describe GpdbDataSource do
  describe "associations" do
    it { should have_many :databases }
  end

  describe "#create" do
    let(:user) { users(:admin) }
    let :valid_input_attributes do
      {
          :name => "create_spec_name",
          :port => 12345,
          :host => "server.emc.com",
          :db_name => "postgres",
          :description => "old description",
          :db_username => "bob",
          :db_password => "secret"
      }
    end

    before do
      any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { true } }
    end

    it "requires db username and password" do
      [:db_username, :db_password].each do |attribute|
        data_source = GpdbDataSource.new(valid_input_attributes.merge(attribute => nil), :as => :create)
        data_source.should_not be_valid
        data_source.should have_error_on(:owner_account)
      end
    end

    it "requires that a real connection to GPDB requires valid credentials" do
      any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { false } }
      data_source = GpdbDataSource.new(valid_input_attributes, :as => :create)
      data_source.should_not be_valid
      data_source.should have_error_on(:owner_account)
    end

    it "can save a new data_source that is shared" do
      data_source = user.gpdb_data_sources.create(valid_input_attributes.merge({:shared => true}), :as => :create)
      data_source.shared.should == true
      data_source.should be_valid
    end
  end

  describe "#create_database" do
    let(:connection) { Object.new }
    let(:data_source) { data_sources(:default) }
    let(:user) { "hiya" }
    let(:database_name) { "things" }

    before do
      stub(data_source).connect_as(user) { connection }
      stub(data_source).refresh_databases { data_source.databases.create(:name => database_name) }
    end

    it "should create the database" do
      mock(connection).create_database(database_name)
      expect do
        data_source.create_database(database_name, user).name.should == database_name
      end.to change(GpdbDatabase, :count).by(1)
    end

    context "when the database is invalid" do
      before do
        any_instance_of(GpdbDatabase) do |database|
          stub(database).valid? { false }
        end
      end

      it "should not create a database" do
        dont_allow(connection).create_database.with_any_args
        expect do
          expect do
            data_source.create_database(database_name, user)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end.not_to change(GpdbDatabase, :count)
      end
    end
  end

  describe "#used_by_workspaces" do
    let!(:gpdb_data_source) { FactoryGirl.create :gpdb_data_source }
    let!(:gpdb_database) { FactoryGirl.create(:gpdb_database, :data_source => gpdb_data_source, :name => 'db') }
    let!(:gpdb_schema) { FactoryGirl.create(:gpdb_schema, :name => 'schema', :database => gpdb_database) }
    let!(:workspace1) { FactoryGirl.create(:workspace, :name => "Z_workspace", :sandbox => gpdb_schema) }
    let!(:workspace2) { FactoryGirl.create(:workspace, :name => "a_workspace", :sandbox => gpdb_schema, :public => false) }
    let!(:workspace3) { FactoryGirl.create(:workspace, :name => "ws_3") }

    it "returns the workspaces that use this data_source's schema as sandbox" do
      workspaces = gpdb_data_source.used_by_workspaces(users(:admin))
      workspaces.count.should == 2
      workspaces.should include(workspace1)
      workspaces.should include(workspace2)
      workspaces.should_not include(workspace3)
    end

    it "only returns workspaces visible to the user" do
      workspaces = gpdb_data_source.used_by_workspaces(users(:not_a_member))
      workspaces.count.should == 1
      workspaces.should include(workspace1)
    end

    it "sorts the workspaces alphabetically" do
      workspaces = gpdb_data_source.used_by_workspaces(users(:admin))
      workspaces.should == [workspace2, workspace1]
    end
  end

  describe "#refresh_databases", :greenplum_integration do
    context "with database integration" do
      let(:account_with_access) { GreenplumIntegration.real_account }
      let(:gpdb_data_source) { account_with_access.data_source }
      let(:database) { GreenplumIntegration.real_database }

      it "adds new database_instance_accounts and enqueues a GpdbDatabase.reindex_datasets" do
        mock(QC.default_queue).enqueue_if_not_queued("GpdbDatabase.reindex_datasets", database.id)
        stub(QC.default_queue).enqueue_if_not_queued("GpdbDatabase.reindex_datasets", anything)
        database.instance_accounts = []
        database.instance_accounts.find_by_id(account_with_access.id).should be_nil
        gpdb_data_source.refresh_databases
        database.instance_accounts.find_by_id(account_with_access.id).should == account_with_access
      end

      it "does not enqueue GpdbDatabase.reindex_datasets if the data_source accounts for a database have not changed" do
        stub(QC.default_queue).enqueue_if_not_queued("GpdbDatabase.reindex_datasets", anything)
        dont_allow(QC.default_queue).enqueue_if_not_queued("GpdbDatabase.reindex_datasets", database.id)
        gpdb_data_source.refresh_databases
      end
    end

    context "with database stubbed" do
      let(:gpdb_data_source) { data_sources(:owners) }
      let(:database) { gpdb_databases(:default) }
      let(:missing_database) { gpdb_data_source.databases.where("id <> #{database.id}").first }
      let(:account_with_access) { gpdb_data_source.owner_account }
      let(:account_without_access) { instance_accounts(:unauthorized) }

      context "when database query is successful" do
        before do
          stub_gpdb(gpdb_data_source.owner_account, gpdb_data_source.send(:database_and_role_sql) => [
              {'database_name' => database.name, 'db_username' => account_with_access.db_username},
              {'database_name' => 'something_new', 'db_username' => account_with_access.db_username}
          ])
        end

        it "creates new databases" do
          gpdb_data_source.databases.where(:name => 'something_new').should_not exist
          gpdb_data_source.refresh_databases
          gpdb_data_source.databases.where(:name => 'something_new').should exist
        end

        it "should not index databases that were just created" do
          stub(QC.default_queue).enqueue_if_not_queued("GpdbDatabase.reindex_datasets", anything) do |method, id|
            GpdbDatabase.find(id).name.should_not == 'something_new'
          end
          gpdb_data_source.refresh_databases
        end

        it "removes database_instance_accounts if they no longer exist" do
          database.instance_accounts << account_without_access
          gpdb_data_source.refresh_databases
          database.instance_accounts.find_by_id(account_without_access.id).should be_nil
        end

        it "marks databases as stale if they no longer exist" do
          missing_database.should_not be_stale
          gpdb_data_source.refresh_databases(:mark_stale => true)
          missing_database.reload.should be_stale
          missing_database.stale_at.should be_within(5.seconds).of(Time.current)
        end

        it "does not mark databases as stale if flag not set" do
          missing_database.should_not be_stale
          gpdb_data_source.refresh_databases
          missing_database.reload.should_not be_stale
        end

        it "clears the stale flag on databases if they are found again" do
          database.mark_stale!
          gpdb_data_source.refresh_databases
          database.reload.should_not be_stale
        end

        it "does not update the stale_at time" do
          Timecop.freeze(1.year.ago) do
            missing_database.mark_stale!
          end
          gpdb_data_source.refresh_databases(:mark_stale => true)
          missing_database.reload.stale_at.should be_within(5.seconds).of(1.year.ago)
        end

        it "calls refresh_schemas" do
          options = {:foo => 'bar'}
          mock(gpdb_data_source).refresh_schemas(options)
          gpdb_data_source.refresh_databases options
        end
      end

      context "when the data_source is not available" do
        before do
          stub_gpdb_fail
        end

        it "marks all the associated databases as stale if the flag is set" do
          gpdb_data_source.refresh_databases(:mark_stale => true)
          database.reload.should be_stale
        end

        it "does not mark the associated databases as stale if the flag is not set" do
          gpdb_data_source.refresh_databases
          database.reload.should_not be_stale
        end
      end
    end
  end

  describe "#connect_with" do
    let(:data_source) { data_sources(:default) }
    let(:account) { instance_accounts(:unauthorized) }

    it "should return a GreenplumConnection" do
      mock(GreenplumConnection).new({
                                        :host => data_source.host,
                                        :port => data_source.port,
                                        :username => account.db_username,
                                        :password => account.db_password,
                                        :database => data_source.db_name,
                                        :logger => Rails.logger
                                    }) { "this is my connection" }
      data_source.connect_with(account).should == "this is my connection"
    end
  end

  describe "#databases", :greenplum_integration do
    let(:account) { GreenplumIntegration.real_account }

    it "should not include the 'template0' database" do
      account.data_source.databases.map(&:name).should_not include "template0"
    end
  end

  describe "#destroy" do
    let(:data_source) { data_sources(:owners) }

    it "destroys dependent databases" do
      databases = data_source.databases
      databases.length.should > 0

      data_source.destroy
      databases.each do |database|
        GpdbDatabase.find_by_id(database.id).should be_nil
      end
    end
  end

  it_should_behave_like :data_source_with_access_control
  it_behaves_like(:data_source_with_update) do
    let(:data_source) { data_sources(:default) }
  end


  describe "DataSource Integration", :greenplum_integration do
    let(:data_source) { GreenplumIntegration.real_data_source }
    let(:account) { data_source.accounts.find_by_owner_id(data_source.owner.id) }

    it_behaves_like :data_source_integration
  end
end