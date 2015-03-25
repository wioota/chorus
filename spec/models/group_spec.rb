require 'spec_helper'

describe Group do
  describe "associations" do
    it { should have_and_belong_to_many(:users) }
    it { should have_one(:scope) }
    it { should have_and_belong_to_many(:roles) }
  end
end
