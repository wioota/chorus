require "spec_helper"

describe AlpineWorkfile do
  describe "validations" do
    it { should validate_presence_of :alpine_id }
  end
end