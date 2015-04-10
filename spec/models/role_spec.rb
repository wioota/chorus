require 'spec_helper'

describe Role do
  describe "associations" do
    it { should have_many(:permissions) }
    it { should have_and_belong_to_many(:users) }
    it { should have_and_belong_to_many(:groups) }
    it { should have_many(:chorus_objects).through(:chorus_object_roles) }
  end
end
