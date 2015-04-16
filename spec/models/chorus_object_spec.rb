require 'spec_helper'

describe ChorusObject do
  describe "associations" do
    it { should belong_to(:chorus_class) }
    it { should belong_to(:scope) }
    it { should belong_to(:owner) }
    it { should have_many(:roles).through(:chorus_object_roles) }
    it { should have_many(:permissions).through(:roles)}
  end

  describe "referenced_object" do

    let (:some_object) { workspaces(:public) }

    it "should return the referenced object" do
      chorus_class = ChorusClass.create(:name => some_object.class.name)
      chorus_object = ChorusObject.create(:chorus_class_id => chorus_class.id, :instance_id => some_object.id)

      expect(chorus_object.referenced_object).to eq(some_object)
    end
  end
end