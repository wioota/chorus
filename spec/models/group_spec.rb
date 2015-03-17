require 'spec_helper'

describe Role do
  describe "associations" do
    it { should have_and_belong_to_many(:user) }
    it { should have_one(:scope) }
    it { should have_many(:permissions) }
  end
end
