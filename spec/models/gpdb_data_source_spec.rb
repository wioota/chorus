require "spec_helper"

describe GpdbDataSource do
  describe "validations" do
    describe "associated account" do
      let(:instance) { data_sources(:shared) }
      context "when host, port, or db_name change" do
        it "validates the account when host changes" do
          mock(instance.owner_account).valid?
          instance.host = 'something_new'
          instance.valid?
        end
        it "validates the account when port changes" do
          mock(instance.owner_account).valid?
          instance.port = '5413'
          instance.valid?
        end
        it "validates the account when db_name changes" do
          mock(instance.owner_account).valid?
          instance.db_name = 'something_new'
          instance.valid?
        end
        it "pulls associated error messages onto the instance" do
          stub(instance).valid_db_credentials? { false }
          instance.db_name = 'something_new'
          instance.valid?
          instance.errors.values.should =~ instance.owner_account.errors.values
        end
      end

      context "when other attributes change" do
        it "does not validate the account" do
          dont_allow(instance.owner_account).valid?
          instance.name = 'purple_bandana'
          instance.valid?
        end
      end
    end
  end

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
        instance = GpdbDataSource.new(valid_input_attributes.merge(attribute => nil), :as => :create)
        instance.should_not be_valid
        instance.should have_error_on(:owner_account)
      end
    end

    it "requires that a real connection to GPDB requires valid credentials" do
      any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { false } }
      instance = GpdbDataSource.new(valid_input_attributes, :as => :create)
      instance.should_not be_valid
      instance.should have_error_on(:owner_account)
    end

    it "can save a new instance that is shared" do
      instance = user.gpdb_data_sources.create(valid_input_attributes.merge({:shared => true}), :as => :create)
      instance.shared.should == true
      instance.should be_valid
    end
  end

  describe "#update" do
    before do
      any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { true } }
    end

    let(:instance) { data_sources(:shared) }

    it "does not allow you to update the shared attribute" do
      instance.update_attributes!(:shared => false)
      instance.shared.should be_true
    end

    it "generates a GreenplumInstanceChangedName event when the name is being changed" do
      set_current_user(instance.owner)
      old_name = instance.name
      instance.update_attributes(:name => 'something_else')
      event = Events::GreenplumInstanceChangedName.find_last_by_actor_id(instance.owner)
      event.gpdb_data_source.should == instance
      event.old_name.should == old_name
      event.new_name.should == 'something_else'
    end

    it "does not generate an event when the name is not being changed" do
      expect {
        instance.update_attributes!(:description => 'hi!')
      }.to_not change(Events::GreenplumInstanceChangedName, :count)
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

  describe ".owned_by" do
    let(:owner) { FactoryGirl.create(:user) }
    let!(:gpdb_shared_instance) { FactoryGirl.create(:gpdb_data_source, :shared => true) }
    let!(:gpdb_owned_instance) { FactoryGirl.create(:gpdb_data_source, :owner => owner) }
    let!(:gpdb_other_instance) { FactoryGirl.create(:gpdb_data_source) }

    context "for owners" do
      it "includes owned gpdb instances" do
        GpdbDataSource.owned_by(owner).should include gpdb_owned_instance
      end

      it "excludes other users' gpdb instances" do
        GpdbDataSource.owned_by(owner).should_not include gpdb_other_instance
      end

      it "excludes shared gpdb instances" do
        GpdbDataSource.owned_by(owner).should_not include gpdb_shared_instance
      end
    end

    context "for non-owners" do
      it "excludes all gpdb instances" do
        GpdbDataSource.owned_by(FactoryGirl.build_stubbed(:user)).should be_empty
      end
    end

    context "for admins" do
      it "includes all gpdb instances" do
        GpdbDataSource.owned_by(users(:evil_admin)).count.should == GpdbDataSource.count
      end
    end
  end

  describe ".unshared" do
    it "returns unshared gpdb instances" do
      gpdb_data_sources = GpdbDataSource.unshared
      gpdb_data_sources.length.should > 0
      gpdb_data_sources.each { |i| i.should_not be_shared }
    end
  end

  describe "#used_by_workspaces" do
    let!(:gpdb_data_source) { FactoryGirl.create :gpdb_data_source }
    let!(:gpdb_database) { FactoryGirl.create(:gpdb_database, :data_source => gpdb_data_source, :name => 'db') }
    let!(:gpdb_schema) { FactoryGirl.create(:gpdb_schema, :name => 'schema', :database => gpdb_database) }
    let!(:workspace1) { FactoryGirl.create(:workspace, :name => "Z_workspace", :sandbox => gpdb_schema) }
    let!(:workspace2) { FactoryGirl.create(:workspace, :name => "a_workspace", :sandbox => gpdb_schema, :public => false) }
    let!(:workspace3) { FactoryGirl.create(:workspace, :name => "ws_3") }

    it "returns the workspaces that use this instance's schema as sandbox" do
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

  describe "#account_for_user!" do
    let(:user) { users(:owner) }

    context "shared gpdb instance" do
      let(:gpdb_data_source) { FactoryGirl.create(:gpdb_data_source, :shared => true) }
      let(:owner_account) { gpdb_data_source.owner_account }

      it "should return the same account for everyone" do
        gpdb_data_source.account_for_user!(user).should == owner_account
        gpdb_data_source.account_for_user!(gpdb_data_source.owner).should == owner_account
      end
    end

    context "individual gpdb instance" do
      let(:gpdb_data_source) { data_sources(:owners) }
      let!(:owner_account) { InstanceAccount.find_by_instance_id_and_owner_id(gpdb_data_source.id, gpdb_data_source.owner.id) }
      let!(:user_account) { InstanceAccount.find_by_instance_id_and_owner_id(gpdb_data_source.id, users(:the_collaborator).id) }

      it "should return the account for the user" do
        gpdb_data_source.account_for_user!(gpdb_data_source.owner).should == owner_account
        gpdb_data_source.account_for_user!(user_account.owner).should == user_account
      end
    end

    context "missing account" do
      let(:gpdb_data_source) { data_sources(:owners) }

      it "raises an exception" do
        expect { gpdb_data_source.account_for_user!(users(:no_collaborators)) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#account_for_user" do
    let(:gpdb_data_source) { data_sources(:owners) }

    context "missing account" do
      it "returns nil" do
        gpdb_data_source.account_for_user(users(:no_collaborators)).should be_nil
      end
    end
  end

  describe "search fields" do
    it "indexes text fields" do
      GpdbDataSource.should have_searchable_field :name
      GpdbDataSource.should have_searchable_field :description
    end
  end

  describe "refresh_databases", :greenplum_integration do
    context "with database integration" do
      let(:account_with_access) { GreenplumIntegration.real_account }
      let(:gpdb_data_source) { account_with_access.instance }
      let(:database) { GreenplumIntegration.real_database }

      it "adds new database_instance_accounts and enqueues a GpdbDatabase.reindex_dataset_permissions" do
        mock(QC.default_queue).enqueue_if_not_queued("GpdbDatabase.reindex_dataset_permissions", database.id)
        stub(QC.default_queue).enqueue_if_not_queued("GpdbDatabase.reindex_dataset_permissions", anything)
        database.instance_accounts = []
        database.instance_accounts.find_by_id(account_with_access.id).should be_nil
        gpdb_data_source.refresh_databases
        database.instance_accounts.find_by_id(account_with_access.id).should == account_with_access
      end

      it "does not enqueue GpdbDatabase.reindex_dataset_permissions if the instance accounts for a database have not changed" do
        stub(QC.default_queue).enqueue_if_not_queued("GpdbDatabase.reindex_dataset_permissions", anything)
        dont_allow(QC.default_queue).enqueue_if_not_queued("GpdbDatabase.reindex_dataset_permissions", database.id)
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
          stub(QC.default_queue).enqueue_if_not_queued("GpdbDatabase.reindex_dataset_permissions", anything) do |method, id|
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
      end

      context "when the instance is not available" do
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
    let(:instance) { data_sources(:default) }
    let(:account) { instance_accounts(:unauthorized) }

    it "should return a GreenplumConnection" do
      mock(GreenplumConnection).new({
                                        :host => instance.host,
                                        :port => instance.port,
                                        :username => account.db_username,
                                        :password => account.db_password,
                                        :database => instance.db_name,
                                        :logger => Rails.logger
                                    }) { "this is my connection" }
      instance.connect_with(account).should == "this is my connection"
    end
  end

  describe "#databases", :greenplum_integration do
    let(:account) { GreenplumIntegration.real_account }

    it "should not include the 'template0' database" do
      account.instance.databases.map(&:name).should_not include "template0"
    end
  end

  describe ".refresh" do
    let(:instance) { data_sources(:owners) }

    before do
      @refreshed_databases = false
      any_instance_of(GpdbDataSource) do |gpdb_data_source|
        stub(gpdb_data_source).refresh_databases { @refreshed_databases = true }
      end

      instance.databases.count.should > 0
      instance.databases.each do |database|
        mock(GpdbSchema).refresh(instance.owner_account, database, :refresh_all => true)
      end
    end

    it "should refresh all databases for the instance" do
      described_class.refresh(instance.id)
      @refreshed_databases.should == true
    end
  end

  describe "automatic reindexing" do
    let(:instance) { data_sources(:owners) }

    before do
      stub(Sunspot).index.with_any_args
    end

    context "making the instance shared" do
      it "should reindex" do
        mock(instance).solr_reindex_later
        instance.shared = true
        instance.save
      end
    end

    context "making the instance un-shared" do
      let(:instance) { data_sources(:shared) }
      it "should reindex" do
        mock(instance).solr_reindex_later
        instance.shared = false
        instance.save
      end
    end

    context "not changing the shared state" do
      it "should not reindex" do
        dont_allow(instance).solr_reindex_later
        instance.update_attributes(:name => 'foo')
      end
    end
  end

  describe "#solr_reindex_later" do
    let(:instance) { data_sources(:owners) }
    it "should enqueue a job" do
      mock(QC.default_queue).enqueue_if_not_queued("GpdbDataSource.reindex_instance", instance.id)
      instance.solr_reindex_later
    end
  end

  describe "#refresh_databases_later" do
    let(:instance) { data_sources(:owners) }
    it "should enqueue a job" do
      mock(QC.default_queue).enqueue_if_not_queued("GpdbDataSource.refresh_databases", instance.id)
      instance.refresh_databases_later
    end
  end

  describe "#reindex_instance" do
    let(:instance) { data_sources(:owners) }

    before do
      stub(Sunspot).index.with_any_args
    end

    it "reindexes itself" do
      mock(Sunspot).index(instance)
      GpdbDataSource.reindex_instance(instance.id)
    end

    it "should reindex all of it's datasets" do
      mock(Sunspot).index(is_a(Dataset)).times(instance.datasets.count)
      GpdbDataSource.reindex_instance(instance.id)
    end
  end

  describe "#destroy" do
    let(:instance) { data_sources(:owners) }

    it "destroys dependent databases" do
      databases = instance.databases
      databases.length.should > 0

      instance.destroy
      databases.each do |database|
        GpdbDatabase.find_by_id(database.id).should be_nil
      end
    end
  end

  describe "DataSource Behaviors", :greenplum_integration do
    let(:instance) { GreenplumIntegration.real_data_source }
    let(:account) { instance.accounts.find_by_owner_id(instance.owner.id) }

    it_should_behave_like "DataSource"
  end
end