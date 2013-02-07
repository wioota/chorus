require "spec_helper"

describe DataSource do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of :db_name }

    it_should_behave_like "it validates with DataSourceNameValidator"

    it_should_behave_like 'a model with name validations' do
      let(:factory_name) { :data_source }
    end

    describe "port" do
      context "when port is not a number" do
        it "fails validation" do
          FactoryGirl.build(:gpdb_data_source, :port => "1aaa1").should_not be_valid
        end
      end

      context "when port is number" do
        it "validates" do
          FactoryGirl.build(:gpdb_data_source, :port => "1111").should be_valid
        end
      end

      context "when host is set but not port" do
        it "fails validation" do
          FactoryGirl.build(:gpdb_data_source, :host => "1111", :port => "").should_not be_valid
        end
      end

      context "when host and port both are not set" do
        it "NO validate" do
          FactoryGirl.build(:gpdb_data_source, :host => "", :port => "").should be_valid
        end
      end
    end
  end

  describe "associations" do
    it { should belong_to :owner }
    it { should have_many :accounts }
    it { should have_one :owner_account }
    it { should have_many :activities }
    it { should have_many :events }
  end

  describe "access control" do
    let(:user) { users(:owner) }

    before(:each) do
      @gpdb_data_source_owned = FactoryGirl.create :gpdb_data_source, :owner => user
      @gpdb_data_source_shared = FactoryGirl.create :gpdb_data_source, :shared => true
      @membership_account = FactoryGirl.build(:instance_account, :owner => user)
      @membership_account.save(:validate => false)
      @gpdb_data_source_with_membership = @membership_account.instance
      @gpdb_data_source_forbidden = FactoryGirl.create :gpdb_data_source
    end

    describe '.accessible_to' do
      it "returns owned gpdb instances" do
        GpdbDataSource.accessible_to(user).should include @gpdb_data_source_owned
      end

      it "returns shared gpdb instances" do
        GpdbDataSource.accessible_to(user).should include @gpdb_data_source_shared
      end

      it "returns gpdb instances to which user has membership" do
        GpdbDataSource.accessible_to(user).should include @gpdb_data_source_with_membership
      end

      it "does not return instances the user has no access to" do
        GpdbDataSource.accessible_to(user).should_not include(@gpdb_data_source_forbidden)
      end
    end

    describe '#accessible_to' do
      it 'returns true if the instance is shared' do
        @gpdb_data_source_shared.accessible_to(user).should be_true
      end

      it 'returns true if the instance is owned by the user' do
        @gpdb_data_source_owned.accessible_to(user).should be_true
      end

      it 'returns true if the user has an instance account' do
        @gpdb_data_source_with_membership.accessible_to(user).should be_true
      end

      it 'returns false otherwise' do
        @gpdb_data_source_forbidden.accessible_to(user).should be_false
      end

    end
  end

  describe 'activity creation' do
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

    it "makes a DataSourceCreated event" do
      set_current_user(user)
      instance = nil
      expect {
        instance = FactoryGirl.create(:data_source, :owner => user)
      }.to change(Events::DataSourceCreated, :count).by(1)
      event = Events::DataSourceCreated.last
      event.data_source.should == instance
      event.actor.should == user
    end
  end

  describe "#destroy" do
    let(:instance) { data_sources(:owners) }

    it "should not delete the database entry" do
      instance.destroy
      expect {
        instance.reload
      }.to_not raise_error(Exception)
    end

    it "should update the deleted_at field" do
      instance.destroy
      instance.reload.deleted_at.should_not be_nil
    end

    it "destroys dependent instance accounts" do
      instance_accounts = instance.accounts
      instance_accounts.length.should > 0

      instance.destroy
      instance_accounts.each do |account|
        InstanceAccount.find_by_id(account.id).should be_nil
      end
    end
  end

  describe '#connect_as_owner' do
    let(:data_source) { data_sources(:oracle) }

    before do
      mock(data_source).connect_with(data_source.owner_account)
    end

    it 'connects with the owners account' do
      data_source.connect_as_owner
    end
  end
end