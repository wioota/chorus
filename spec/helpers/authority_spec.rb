require File.dirname(__FILE__) + '/../spec_helper'


describe Authority do

  before :all do
    class TestModel
      include Permissioner
      PERMISSIONS = [:up, :down, :left, :right]
    end
  end

  context "authorize!" do
    let(:role) { roles(:a_role) }
    let(:arbitrary_user) { users(:admin) }

    it "authorizes a user with correct permissions" do
      role.users << arbitrary_user
      TestModel.create_permissions_for role, [:up, :down]
      test_model = TestModel.new

      expect { Authority.authorize! :up, test_model, arbitrary_user }.to_not raise_error
      expect { Authority.authorize! :left, test_model, arbitrary_user }.to raise_error
    end

    it "doesn't authorize a user/activity with incorrect permissions" do
      expect { Authority.authorize! :up, test_model, arbitrary_user }.to raise_error
    end
  end
end