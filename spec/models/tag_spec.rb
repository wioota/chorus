require 'spec_helper'

describe Tag do
  describe 'validations' do
    it { should validate_presence_of :name }

    it 'validates uniqueness of name' do
      Tag.create(:name => 'exists')
      duplicate = Tag.new(:name => 'exists')
      duplicate.should_not be_valid
      duplicate.should have_error_on(:name).with_message(:taken)
    end
  end
end