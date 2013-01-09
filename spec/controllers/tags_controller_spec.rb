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

      a_index = decoded_response.index { |tag|
        tag[:name] == "atag"
      }
      capital_a_index = decoded_response.index { |tag|
        tag[:name] == "Atag"
      }

      capital_a_index.should < a_index

      last_tag = decoded_response.first
      decoded_response.each do |tag|
        tag[:name].downcase.should >= last_tag[:name].downcase
        last_tag = tag
      end
    end

    context "with no query" do
      it "should show all tags" do
        mock_present do |collection|
          collection.should == ActsAsTaggableOn::Tag.all
        end

        get :index
      end
    end

    context "with a search query" do
      it "should show only tags that contain the search text" do
        mock_present do |collection|
          collection.length == 1
          collection.first.name.should == 'beta'
        end

        get :index, :q => "ET"
      end
    end
  end

  describe "jasmine fixtures" do
    def self.generate_tags_fixture
      generate_fixture "tagSet.json" do
        get :index
      end
    end

    generate_tags_fixture
  end
end