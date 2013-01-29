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
end