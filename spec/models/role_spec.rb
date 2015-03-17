require 'spec_helper'

describe Role do
  describe "associations" do
    it { should have_many(:permissions) }
    it { should have_and_belong_to_many(:users) }
    it { should have_and_belong_to_many(:groups) }

   # it "has_many permissions" do
   #   Role.reflect_on_association(:permissions).macro.should == :has_many
   # end
   # it "has_and_belong_to_many users" do
   #   Role.reflect_on_association(:users).macro.should == :has_and_belongs_to_many
   # end
   # it "has_and_belong_to_many groups" do
   #   Role.reflect_on_association(:groups).macro.should == :has_and_belongs_to_many
   # end
  end
end
