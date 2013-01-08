require 'spec_helper'

describe Oracle::InstanceRegistrar do
  describe ".create!" do
    let(:owner) { users(:owner)}
    let(:valid_input_attributes) {
      {
          :name => 'New oracle instance',
          :host => 'oracle.com',
          :port => 1234,
          :db_name => 'database'
      }
    }

    it "saves the db name, owner and connection params" do
      expect {
        Oracle::InstanceRegistrar.create!(valid_input_attributes, owner)
      }.to change(OracleInstance, :count).by(1)
      instance = OracleInstance.find_by_name(valid_input_attributes[:name])
      instance.host.should == valid_input_attributes[:host]
      instance.port.should == valid_input_attributes[:port]
      instance.db_name.should == valid_input_attributes[:db_name]
      instance.description.should == valid_input_attributes[:description]
      #instance.owner.should == owner
    end

    it "requires name" do
      expect {
        Oracle::InstanceRegistrar.create!(valid_input_attributes.merge(:name => nil), owner)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "requires db connection params" do
      [:db_name, :host, :port].each do |attribute|
        expect {
          Oracle::InstanceRegistrar.create!(valid_input_attributes.merge(attribute => nil), owner)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    xit "requires db username and password" do
      [:db_username, :db_password].each do |attribute|
        expect {
          Oracle::InstanceRegistrar.create!(valid_input_attributes.merge(attribute => nil), owner)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    xit "requires that a real connection to Oracle can be established" do
      stub(Oracle::ConnectionChecker).check! { raise ApiValidationError.new }

      expect {
        expect {
          Oracle::InstanceRegistrar.create!(valid_input_attributes, owner)
        }.to raise_error
      }.not_to change(OracleInstance, :count)
    end

    xit "caches the db username and password" do
      expect {
        Oracle::InstanceRegistrar.create!(valid_input_attributes, owner)
      }.to change { InstanceAccount.count }.by(1)

      cached_instance = OracleInstance.find_by_name_and_owner_id(valid_input_attributes[:name], owner.id)
      cached_instance_account = InstanceAccount.find_by_owner_id_and_Oracle_instance_id(owner.id, cached_instance.id)

      cached_instance_account.db_username.should == valid_input_attributes[:db_username]
      cached_instance_account.db_password.should == valid_input_attributes[:db_password]
    end

    xit "can save a new instance that is shared" do
      instance = Oracle::InstanceRegistrar.create!(valid_input_attributes.merge({:shared => true}), owner)
      instance.shared.should == true
    end

    xit "sets the instance_provider on the instance" do
      instance = Oracle::InstanceRegistrar.create!(valid_input_attributes, owner)
      instance[:instance_provider].should == "Greenplum Database"
    end
  end
end