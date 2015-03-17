require 'spec_helper'

describe ChorusObject do
  describe "associations" do
    it { should belong_to(:scope) }
  end
end