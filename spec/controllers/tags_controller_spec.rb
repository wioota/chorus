require 'spec_helper'

describe TagsController do
  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe '#index' do
    it_behaves_like "a paginated list"

    it "sorts the results alphabetically regardless of case" do
      Tag.delete_all
      FactoryGirl.create :tag, :name => 'btag'
      FactoryGirl.create :tag, :name => 'Atag'
      FactoryGirl.create :tag, :name => 'ctag'

      get :index

      decoded_response.map(&:name).should == %w{Atag btag ctag}
    end

    context "with no query" do
      it "should show all tags" do
        mock_present do |collection|
          collection.should == Tag.all.sort { |a, b| a.name <=> b.name }
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

  describe '#delete' do
    let(:dataset) { datasets(:tagged) }
    let(:workfile) { workfiles(:tagged) }
    let(:tag) { Tag.find_by_name('alpha') }

    it 'deletes the tag' do
      dataset.tags.map(&:name).should include(tag.name)
      workfile.tags.map(&:name).should include(tag.name)

      delete :destroy, :id => tag.id
      response.code.should == "200"

      Tag.where(:name => 'alpha').should be_empty
      dataset.reload.tags.map(&:name).should_not include(tag.name)
      workfile.reload.tags.map(&:name).should_not include(tag.name)
    end

    context "when the tag with the specified ID does not exist" do
      it "404s" do
        delete :destroy, :id => "56789"
        response.code.should == "404"
      end
    end
  end

  describe '#update' do
    let(:tag) { Tag.create!(:name => "my name") }

    it "updates the tag's name" do
      expect do
        put :update, { :id => tag.id, :name => "my new name"}
      end.to change { tag.reload.name }.from("my name").to("my new name")

      response.should be_ok
    end

    it "fails to save when the name is invalid" do
      other_tag = Tag.create!(:name => "my other name")

      expect do
        put :update, { :id => tag.id, :name => "my other name" }
      end.to_not change { tag.reload.name }.to("my other name")

      response.should_not be_ok
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