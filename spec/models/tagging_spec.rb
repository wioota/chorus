require 'spec_helper'

describe Tagging do
  describe 'validations' do
    it { should validate_presence_of :tag }
    it { should validate_presence_of :entity }

    it 'only allows unique mappings' do
      existing_tag = taggings(:default)
      duplicate = FactoryGirl.build(:tagging, :entity => existing_tag.entity, :tag => existing_tag.tag)
      duplicate.should_not be_valid
      duplicate.should have_error_on(:tag_id).with_message(:taken)
    end
  end
end