require 'spec_helper'
require 'sunspot'

describe SearchableHtml do
  describe ".searchable_html" do
    #TODO: Get this working, it's close
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
    #
    #before do
    #  Sunspot.session = Sunspot.session.original_session
    #end
    #
    #it "removes tags from the body" do
    #  any_instance_of(RSolr::Connection) do |connection|
    #    mock(connection).execute.with_any_args do |client, request_context|
    #      throw :success, "success" if request_context[:data].match %r{this\s+is\s+text}
    #    end
    #  end
    #
    #  obj = TestClass.new(:html_field => 'this <b>is text</b>')
    #
    #  catch(:success) {
    #    obj.solr_index
    #    false
    #  }.should == "success"
    #end
  end
end