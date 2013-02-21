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
    let(:instance) { data_sources(:oracle) }
    let(:connection) { Object.new }
    let!(:stale_schema) { instance.schemas.create(:name => 'test_schema') }

    before do
      mock(OracleConnection).new(anything) {
        connection
      }

      mock(connection).schemas { ["schema_one", "schema_two"] }
    end

    it "returns the OracleSchemas in the data source" do
      schemas = instance.refresh_schemas
      schemas.map(&:name).should =~ ["schema_one", "schema_two"]
      schemas.all { |schema| schema.class == OracleSchema }.should be_true
    end

    it "updates the data sources schemas" do
      expect { instance.refresh_schemas }.to change(stale_schema, :stale_at)
    end
  end
end