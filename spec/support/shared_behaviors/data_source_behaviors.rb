shared_examples_for :data_source_integration do
  describe "#valid_db_credentials?" do
    it "returns true when the credentials are valid" do
      instance.valid_db_credentials?(account).should be_true
    end

    it "returns true when the credentials are invalid" do
      account.db_username = 'awesome_hat'
      instance.valid_db_credentials?(account).should be_false
    end

    it "raises a DataSourceConnection::Error when other errors occur" do
      instance.host = 'something_fake'
      expect {
        instance.valid_db_credentials?(account)
      }.to raise_error(DataSourceConnection::Error)
    end
  end
end

shared_examples_for :data_source_with_access_control do
  let(:factory_name) { described_class.name.underscore.to_sym }
  describe "access control" do
    let(:user) { users(:owner) }

    before do
      @data_source_owned = FactoryGirl.create factory_name, :owner => user
      @data_source_shared = FactoryGirl.create factory_name, :shared => true
      @data_source_with_membership = FactoryGirl.create factory_name
      @data_source_forbidden = FactoryGirl.create factory_name

      @membership_account = FactoryGirl.build :instance_account, :owner => user, :instance => @data_source_with_membership
      @membership_account.save(:validate => false)
    end

    describe '.accessible_to' do
      it "returns owned instances" do
        described_class.accessible_to(user).should include @data_source_owned
      end

      it "returns shared instances" do
        described_class.accessible_to(user).should include @data_source_shared
      end

      it "returns data source instances to which user has membership" do
        described_class.accessible_to(user).should include @data_source_with_membership
      end

      it "does not return instances the user has no access to" do
        described_class.accessible_to(user).should_not include(@data_source_forbidden)
      end
    end

    describe '#accessible_to' do
      it 'returns true if the instance is shared' do
        @data_source_shared.accessible_to(user).should be_true
      end

      it 'returns true if the instance is owned by the user' do
        @data_source_owned.accessible_to(user).should be_true
      end

      it 'returns true if the user has an instance account' do
        @data_source_with_membership.accessible_to(user).should be_true
      end

      it 'returns false otherwise' do
        @data_source_forbidden.accessible_to(user).should be_false
      end
    end
  end

  describe ".unshared" do
    it "returns unshared gpdb instances" do
      unshared_data_sources = described_class.unshared
      unshared_data_sources.length.should > 0
      unshared_data_sources.each { |i| i.should_not be_shared }
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of :db_name }

    it_should_behave_like "it validates with DataSourceNameValidator" do
      subject { FactoryGirl.create factory_name }
    end

    it_should_behave_like 'a model with name validations'

    context "when host, port, or db_name change" do
      let(:instance_account) { FactoryGirl.build :instance_account }
      let(:instance) { FactoryGirl.build factory_name, :owner_account => instance_account }

      before do
        instance.save!(:validate => false)
        stub(instance).owner_account { instance_account }
        mock(instance_account).valid? { true }
      end

      it "validates the account when host changes" do
        instance.host = 'something_new'
        instance.valid?.should be_true
      end

      it "validates the account when port changes" do
        instance.port = '5413'
        instance.valid?.should be_true
      end

      it "validates the account when db_name changes" do
        instance.db_name = 'something_new'
        instance.valid?.should be_true
      end

      it "pulls associated error messages onto the instance" do
        stub(instance).valid_db_credentials? { false }
        instance.db_name = 'something_new'
        instance.valid?.should be_true
        instance.errors.values.should =~ instance.owner_account.errors.values
      end
    end

    describe "when name changes" do
      let!(:instance) { FactoryGirl.create factory_name }
      it "it does not validate the account" do
        any_instance_of(InstanceAccount) do |account|
          dont_allow(account).valid?
        end
        instance.name = 'purple_bandana'
        instance.valid?.should be_true
      end
    end

    describe "port" do
      context "when port is not a number" do
        it "fails validation" do
          FactoryGirl.build(factory_name, :port => "1aaa1").should_not be_valid
        end
      end

      context "when port is number" do
        it "validates" do
          FactoryGirl.build(factory_name, :port => "1111").should be_valid
        end
      end

      context "when host is set but not port" do
        it "fails validation" do
          FactoryGirl.build(factory_name, :host => "1111", :port => "").should_not be_valid
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
        instance = FactoryGirl.create(factory_name, :owner => user)
      }.to change(Events::DataSourceCreated, :count).by(1)
      event = Events::DataSourceCreated.last
      event.data_source.should == instance
      event.actor.should == user
    end
  end

  describe "#destroy" do
    let(:instance) { FactoryGirl.create factory_name }

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
    let(:data_source) { FactoryGirl.build factory_name }

    before do
      mock(data_source).connect_with(data_source.owner_account)
    end

    it 'connects with the owners account' do
      data_source.connect_as_owner
    end
  end
end