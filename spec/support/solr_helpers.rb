module SolrHelpers
  class SearchSpecHelper
    def self.indexed=(value)
      @@indexed = value
    end

    def self.indexed?
      @@indexed ||= false
    end
  end

  def reindex_solr_fixtures
    stub(DatasetColumn).columns_for.with_any_args {
      [ DatasetColumn.new(:name => 'bogus'),
        DatasetColumn.new(:name => 'bogus 2')
      ]
    }

    #For the searchquery_table fixture specifically, return searchquery columns
    searchquery_dataset = datasets(:searchquery_table)

    stub(DatasetColumn).columns_for(anything, searchquery_dataset) {
      [ DatasetColumn.new(:name => 'searchquery', :description => "searchquery column description"),
        DatasetColumn.new(:name => 'searchquery 2', :description => "searchquery column description 2")
      ]
    }

    any_instance_of(Dataset) do |ds|
      stub(ds).table_description { "bogus" }
    end

    #For the searchquery_table fixture specifically, return a searchquery description
    stub(searchquery_dataset).table_description { "searchquery table description" }

    VCR.use_cassette('search_solr_index') do
      Sunspot.session = Sunspot.session.original_session
      Sunspot.session.remove_all
      Sunspot.searchable.each do |model|
        model.solr_index(:batch_commit => false)
      end
      Sunspot.commit

      searchquery_dataset.solr_index!
      datasets(:typeahead_oracle_table).solr_index!
    end
  end

  def index_solr_fixtures_once
    #This is almost all a workaround for running reindex_solr_fixtures in a before(:all)
    #Even if the reindex were to work in the before(:all), you need to reassign Sunspot.session
    if SearchSpecHelper.indexed?
      Sunspot.session = Sunspot.session.original_session
    else
      reindex_solr_fixtures
      SearchSpecHelper.indexed=true
    end
  end

end