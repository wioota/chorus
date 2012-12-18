require 'spec_helper'

describe TagPresenter, :type => :view do
  let(:presenter)  { TagPresenter.new(tag, view) }
  let(:tag) { ActsAsTaggableOn::Tag.new(:name => "foo") }

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "should have the name" do
      hash.should == { :name => 'foo' }
    end
  end
end
