require 'spec_helper'

describe ChorusObjectRole do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:chorus_object) }
    it { should belong_to(:role) }
  end
end