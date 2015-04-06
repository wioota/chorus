require 'spec_helper'

describe Permissioner do


  describe "create_permissions_for" do
    before :all do
      class TestModel
        include Permissioner
        PERMISSIONS = [:up, :down, :left, :right]
      end

    end

    let (:role) { roles(:a_role) }
    let (:arbitrary_user) { users(:admin) }
    let (:the_permissions) { [:up, :down] }

    before :each do
      TestModel.create_permissions_for(role, the_permissions)
    end

    it "should create a chorus_class if there isn't one for the given model" do
      ChorusClass.find_by_name("TestModel").should_not be_nil
    end

    it "should create .permissions on the chorus_class" do
       ChorusClass.find_by_name("TestModel").permissions.should have_exactly(1).items
    end

  end
end
