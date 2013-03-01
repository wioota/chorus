require 'spec_helper'

describe OracleDataSource do
  let(:instance) { FactoryGirl.build(:oracle_data_source) }

  describe "validations" do
    it { should validate_presence_of(:host) }
    it { should validate_presence_of(:port) }

    context "when creating" do
      it "should validate owner account" do
        mock(instance).owner_account { mock(FactoryGirl.build(:instance_account)).valid? { true } }
        instance.valid?
      end
    end
  end

  describe "owner_account" do
    it "is created automatically" do
      instance = FactoryGirl.build(:oracle_data_source, :owner_account => nil)
      stub(instance).valid_db_credentials?(anything) { true }
      instance.save!
      instance.owner_account.should_not be_nil
    end
  end

  it_should_behave_like :data_source_with_access_control

  describe "DataSource Integration", :oracle_integration do
    let(:instance) { OracleIntegration.real_data_source }
    let(:account) { instance.accounts.find_by_owner_id(instance.owner.id) }

    it_should_behave_like :data_source_integration
  end

  describe ".type_name" do
    it "is Instance" do
      subject.type_name.should == 'Instance'
    end
  end

  describe "#schemas" do
    let(:new_oracle) { FactoryGirl.create(:oracle_data_source) }
    let(:schema) { OracleSchema.create!(:name => 'test_schema', :data_source => new_oracle) }

    it "includes schemas" do
      new_oracle.schemas.should include schema
    end
  end

  describe "#refresh_databases" do
    it "calls refresh_schemas" do
      options = {:foo => 'bar'}
      mock(instance).refresh_schemas(options)
      instance.refresh_databases(options)
    end
  end

  describe "#refresh_schemas" do
    let(:data_source) { data_sources(:oracle) }

    it 'returns the OracleSchemas in the data source' do
      mock(Schema).refresh(data_source.owner_account, data_source, {:refresh_all => true}) { ["schemas"] }
      stub(data_source).update_permissions
      schemas = data_source.refresh_schemas
      schemas.should =~ ["schemas"]
    end

    it 'updates permissions' do
      stub(Schema).refresh.with_any_args
      mock(data_source).update_permissions
      data_source.refresh_schemas
    end
  end

  describe "#update_permissions", :oracle_integraion do
    let(:data_source) { OracleIntegration.real_data_source }
    let(:schema) { OracleIntegration.real_schema }
    let(:account_with_access) { data_source.owner_account }

    it "adds new instance accounts to each Schema" do
      schema.instance_accounts = []
      schema.instance_accounts.find_by_id(account_with_access.id).should be_nil
      data_source.update_permissions
      schema.instance_accounts.find_by_id(account_with_access.id).should == account_with_access
    end
  end
end