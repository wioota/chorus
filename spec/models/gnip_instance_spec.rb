require 'spec_helper'

describe GnipInstance do
  describe "validations" do
    it { should validate_presence_of :stream_url }
    it { should validate_presence_of :name }
    it { should validate_presence_of :username }
    it { should validate_presence_of :password }
    it { should validate_presence_of :owner }

    it_should_behave_like "it validates with DataSourceNameValidator"

    it_should_behave_like 'a model with name validations' do
      let(:factory_name) { :gnip_instance }
    end
  end

  describe "associations" do
    it { should belong_to(:owner).class_name('User') }
    it { should have_many :events }
    it { should have_many :activities }
  end
end