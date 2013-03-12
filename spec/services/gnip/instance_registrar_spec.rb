require 'spec_helper'

describe Gnip::DataSourceRegistrar do
  let(:owner) { users(:owner) }

  let(:instance_attributes) do
    {
        :name => "new_gnip_data_source",
        :description => "some description",
        :stream_url => "https://historical.gnip.com/fake",
        :username => "gnip_username",
        :password => "gnip_password",
        :owner => owner
    }
  end

  describe ".create!" do

    context "with Valid credentials" do
      before do
        any_instance_of(ChorusGnip) do |c|
          mock(c).auth { true }
        end
      end

      it "save the instance" do
        instance = Gnip::DataSourceRegistrar.create!(instance_attributes, owner)

        instance.should be_persisted
        instance.name.should == "new_gnip_data_source"
        instance.description.should == "some description"
        instance.stream_url.should == "https://historical.gnip.com/fake"
        instance.username.should == "gnip_username"
        instance.password.should == "gnip_password"
        instance.id.should_not be_nil
        instance.should be_valid
      end

      it "makes a GnipDataSourceCreated event" do
        instance = Gnip::DataSourceRegistrar.create!(instance_attributes, owner)

        event = Events::GnipDataSourceCreated.last
        event.gnip_data_source.should == instance
        event.actor.should == owner
      end
    end

    context "With Invalid credentials" do
      before do
        any_instance_of(ChorusGnip) do |c|
          mock(c).auth { false }
        end
      end
      it "raise an error" do
        expect {
          Gnip::DataSourceRegistrar.create!(instance_attributes, owner)
        }.to raise_error(ApiValidationError)
      end
    end
  end

  describe ".update!" do

    let(:gnip_data_source) { gnip_data_sources(:default) }

    context "with Valid credentials" do

      let(:new_owner) { users(:not_a_member) }

      before do
        instance_attributes.merge!({:owner => JSON.parse(new_owner.to_json)})
        any_instance_of(ChorusGnip) do |c|
          mock(c).auth { true }
        end
      end

      it "save the instance" do
        instance = Gnip::DataSourceRegistrar.update!(gnip_data_source.id, instance_attributes)

        instance.should be_persisted
        instance.name.should == "new_gnip_data_source"
        instance.description.should == "some description"
        instance.stream_url.should == "https://historical.gnip.com/fake"
        instance.username.should == "gnip_username"
        instance.password.should == "gnip_password"
        instance.id.should_not be_nil
        instance.should be_valid
      end

      it "should ignore an empty password" do
        instance_attributes[:password] = ""
        instance = Gnip::DataSourceRegistrar.update!(gnip_data_source.id, instance_attributes)
        instance.reload
        instance.password.should_not be_blank
      end

      it "should strip out the owner" do
        instance = Gnip::DataSourceRegistrar.update!(gnip_data_source.id, instance_attributes)
        instance.owner.should_not == new_owner
      end
    end

    context "With Invalid credentials" do
      before do
        any_instance_of(ChorusGnip) do |c|
          mock(c).auth { false }
        end
      end

      it "raise an error" do
        expect {
          Gnip::DataSourceRegistrar.update!(gnip_data_source.id, instance_attributes)
        }.to raise_error(ApiValidationError)
      end
    end
  end
end