module SolrHelpers

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

    any_instance_of(GpdbDataset) do |ds|
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
    end
  end
end