require 'spec_helper'
require 'sunspot'

describe SearchableHtml do
  describe ".searchable_html" do
    before do
      Sunspot.session = Sunspot.session.original_session

      class TestClass < ActiveRecord::Base
        @columns = []
        include SearchableHtml

        attr_accessor :html_field, :id
        attr_accessible :html_field

        searchable_html :html_field
      end
    end

    after do
      Sunspot.searchable.instance_variable_get(:@name_to_klass).delete(TestClass.name.to_sym)
    end

    it "removes tags from the body" do
      VCR.use_cassette("searchable_html") do
        Sunspot.session.remove_all
        obj = TestClass.new(:html_field => 'this <b>is text</b>')
        obj.id = 1
        obj.solr_index
        Sunspot.commit

        results = TestClass.search { fulltext "text" }
        results.hits[0].stored('html_field')[0].should == 'this is text'
      end
    end
  end
end