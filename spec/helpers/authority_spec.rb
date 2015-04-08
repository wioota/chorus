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
    let(:arbitrary_user) { users(:default) }

    it "authorizes a user with correct permissions" do
      role.users << arbitrary_user
      TestModel.create_permissions_for role, [:up, :down]
      test_model = TestModel.new

      expect { Authority.authorize! :up, test_model, arbitrary_user }.to_not raise_error
      expect { Authority.authorize! :left, test_model, arbitrary_user }.to raise_error
    end

    it "doesn't authorize a user/activity with incorrect permissions" do
      role.users << arbitrary_user
      TestModel.create_permissions_for role, [:up, :down]
      test_model = TestModel.new

      expect { Authority.authorize! :left, test_model, arbitrary_user }.to raise_error
      expect { Authority.authorize! :right, test_model, arbitrary_user }.to raise_error
    end

    it "allows the owner to make changes regardless of permissions" do
      test_model = TestModel.new
      owner = arbitrary_user

      any_instance_of(TestModel) do |m|
        stub(m).owner { owner }
      end

      expect { Authority.authorize! :anything, test_model, owner }.not_to raise_error
    end

    it "finds the correct owner for objects that use actor instead of owner" do
      test_model = TestModel.new
      actor = arbitrary_user

      any_instance_of(TestModel) do |m|
        stub(m).actor { actor }
      end

      expect { Authority.authorize! :anything, test_model, actor }.not_to raise_error
    end
  end
end