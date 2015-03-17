require 'spec_helper'

describe Permission do
  describe "associations" do
    it { should belong_to(:role) }
  end
end