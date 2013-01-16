require 'spec_helper'

describe DataSources::OwnerController do
  let(:data_source) { data_sources(:shared) }
  let(:user) { data_source.owner }
  let(:new_owner) { users(:no_collaborators) }

  ignore_authorization!

  before do
    log_in user
  end

  describe "#update" do
    def request_ownership_update
      put :update, :data_source_id => data_source.to_param, :owner => {:id => new_owner.to_param }
    end

    it "uses authorization" do
      mock(controller).authorize!(:edit, data_source)
      request_ownership_update
    end

    it "switches ownership of instance and account" do
      mock(Gpdb::InstanceOwnership).change(user, data_source, new_owner)
      request_ownership_update
    end

    it "presents the gpdb instance" do
      stub(Gpdb::InstanceOwnership).change(user, data_source, new_owner)
      mock_present { |instance_presented| instance_presented.should == data_source }
      request_ownership_update
    end
  end
end
