require 'spec_helper'

describe TagsController do
  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe 'index' do
    it_behaves_like "a paginated list"

    it "should sort the results alphabetically regardless of case" do
      ActsAsTaggableOn::Tag.create(:name => 'btag')
      ActsAsTaggableOn::Tag.create(:name => 'Atag')
      ActsAsTaggableOn::Tag.create(:name => 'atag')

      get :index

      a_index = decoded_response.index({'name' => "atag"})
      capital_a_index = decoded_response.index({'name' => "Atag"})

      capital_a_index.should < a_index

      last_tag = decoded_response.first
      decoded_response.each do |tag|
        tag[:name].downcase.should >= last_tag[:name].downcase
        last_tag = tag
      end
    end

    context "with no query" do
      it "should show all tags" do
        get :index
        decoded_response.should == ActsAsTaggableOn::Tag.all.map { |tag| {'name' => tag.name} }
      end
    end

    context "with a search query" do
      it "should show only tags that contain the search text" do
        get :index, :q => "ET"
        decoded_response.should == [{'name' => 'beta'}]
      end
    end
  end
end