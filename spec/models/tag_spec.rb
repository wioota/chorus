require 'spec_helper'

describe Tag do
  describe "polymorphicism" do
    it "can belong to multiple types" do
      table = FactoryGirl.create(:gpdb_table)
      table.tags << Tag.new(:name => "fancy tag")
      table.reload.tags.last.name.should == "fancy tag"

      view = FactoryGirl.create(:gpdb_view)
      view.tags << Tag.new(:name => "different tag")
      view.reload.tags.last.name.should == "different tag"
    end
  end

  describe "search fields" do
    it "indexes the tag name" do
      Tag.should have_searchable_field :name
    end
  end

  describe "#named_like" do
    it "returns tags based on substring match" do
      Tag.create!(:name => "abc")
      Tag.create!(:name => "ABD")
      Tag.create!(:name => "abe")
      Tag.create!(:name => "xyz")

      matching_tags = Tag.named_like("ab")

      matching_tags.map(&:name).should =~ ["abc", "ABD", "abe"]
    end

    it "is not vulnerable to sql injection" do
      Tag.named_like("'drop tables").to_sql.should match /\(name ILIKE '%''drop tables%'\)/
    end
  end
end