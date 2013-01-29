require "spec_helper"

describe AlpineWorkfile do
  describe "validations" do
    it { should validate_presence_of :alpine_id }
  end

  describe "entity_subtype" do
    it "should return 'alpine'" do
      AlpineWorkfile.new.entity_subtype.should == 'alpine'
    end
  end
end