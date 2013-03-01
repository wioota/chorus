require 'spec_helper'

describe GnipInstance do
  it_behaves_like "a notable model" do
    let!(:note) do
      Events::NoteOnGnipInstance.create!({
        :actor => users(:owner),
        :gnip_instance => model,
        :body => "This is the body"
      }, :as => :create)
    end

    let!(:model) { FactoryGirl.create(:gnip_instance) }
  end

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

  it_should_behave_like "taggable models", [:gnip_instances, :default]

end