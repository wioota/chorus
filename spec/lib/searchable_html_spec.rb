require 'spec_helper'
require 'sunspot'

describe SearchableHtml do
  describe ".searchable_html" do
    #
    #class TestClass < ActiveRecord::Base
    #  @columns = []
    #  include SearchableHtml
    #
    #  attr_accessor :html_field
    #  attr_accessible :html_field
    #
    #  searchable_html :html_field
    #end

    # TODO: this is test in search_spec.rb but it would be better to test this here
    #it "removes tags from the body" do
      #Sunspot.searchable << TestClass
      #
      #obj = TestClass.new(:html_field => 'this<div>is text</div>')
      #obj.solr_index

      #comment = Comment.last
      #comment.body = 'this<div>is text</div>'
      #comment.search_body.should == 'this is text'
    #end
  end
end