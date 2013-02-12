module SolrHelpers

  def reindex_solr_fixtures
    stub(DatasetColumn).columns_for.with_any_args {
      [ DatasetColumn.new(:name => 'bogus'),
        DatasetColumn.new(:name => 'bogus 2')
      ]
    }
    any_instance_of(GpdbDataset) do |ds|
      stub(ds).table_description { "bogus" }
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
