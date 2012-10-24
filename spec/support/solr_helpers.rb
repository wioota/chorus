module SolrHelpers

  def reindex_solr_fixtures
    stub(GpdbColumn).columns_for.with_any_args {
      [ GpdbColumn.new(:name => 'searchquery'),
        GpdbColumn.new(:name => 'searchquery 2'),
        GpdbColumn.new(:name => 'non-search'),
        GpdbColumn.new(:name => 'comment-search', :description => 'searchquery comment 1'),
        GpdbColumn.new(:name => 'comment-search-2', :description => 'searchquery comment 2')
      ]
    }
    any_instance_of(Dataset) do |ds|
      stub(ds).table_description { "searchquery" }
    end
    VCR.use_cassette('search_solr_index') do
      Sunspot.session = Sunspot.session.original_session
      Sunspot.session.remove_all
      Sunspot.searchable.each do |model|
        model.solr_index(:batch_commit => false)
      end
      Sunspot.commit
    end
  end
end
