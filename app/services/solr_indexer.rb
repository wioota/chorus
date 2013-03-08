module SolrIndexer
  def self.refresh_and_reindex(types)
    self.refresh_external_data
    self.reindex(types)
  end

  def self.reindex(types)
    Rails.logger.info("Starting Solr Re-Index")
    types_to_index(types).each(&:solr_reindex)
    Sunspot.commit
    Rails.logger.info("Solr Re-Index Completed")
  end

  def self.refresh_external_data
    Rails.logger.info("Starting Solr Refresh")
    DataSource.find_each do |ds|
      QC.enqueue_if_not_queued("DataSource.refresh", ds.id, 'mark_stale' => true, 'force_index' => false)
    end
    HdfsDataSource.find_each do |ds|
      QC.enqueue_if_not_queued("HdfsDataSource.refresh", ds.id)
    end
    Rails.logger.info("Solr Refreshes Queued")
  end

  private

  def self.types_to_index(types)
    types = Array(types)
    types = types.reject { |t| t.blank? }

    if types.include? "all"
      Sunspot.searchable
    else
      types.map(&:constantize)
    end
  end
end