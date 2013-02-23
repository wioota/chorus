require 'spec_helper'

describe OracleDataSource do
  describe "validations" do
    let(:instance) { FactoryGirl.build(:oracle_data_source) }

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

  describe "#schemas" do
    let(:new_oracle) { FactoryGirl.create(:oracle_data_source) }
    let(:schema) { OracleSchema.create!(:name => 'test_schema', :data_source => new_oracle) }

    it "includes schemas" do
      new_oracle.schemas.should include schema
    end
  end

  describe "#refresh_schemas" do
    let(:data_source) { data_sources(:oracle) }

    before do
      mock(Schema).refresh(data_source.owner_account, data_source, {:refresh_all => true}) { ["schemas"] }
    end

    it "returns the OracleSchemas in the data source" do
      schemas = data_source.refresh_schemas
      schemas.should =~ ["schemas"]
    end
  end
end