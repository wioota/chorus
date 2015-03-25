require 'spec_helper'

describe Permission do
  describe "associations" do
    it { should belong_to(:role) }
    it { should belong_to(:chorus_class) }
  end
end