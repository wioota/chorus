require 'spec_helper'

describe ChorusObject do
  describe "associations" do
    it { should belong_to(:scope) }
    it { should belong_to(:chorus_class) }
    it { should have_many(:roles).through(:chorus_object_roles) }
  end
end