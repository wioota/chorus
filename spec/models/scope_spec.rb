require 'spec_helper'

describe Scope do
  describe "associations" do
    it { should belong_to(:group) }
    it { should have_many(:chorus_objects) }
  end
end