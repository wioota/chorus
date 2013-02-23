module SolrIndexer
  def self.refresh_and_reindex(types)
    self.refresh_external_data false
    self.reindex(types)
  end

  def self.reindex(types)
    Rails.logger.info("Starting Solr Re-Index")
    types_to_index(types).each(&:solr_reindex)
    Sunspot.commit
    Rails.logger.info("Solr Re-Index Completed")
  end

  def self.refresh_external_data(force_index = true)
    Rails.logger.info("Starting Solr Refresh")
    DataSource.find_each do |data_source|
      data_source.refresh(:mark_stale => true, :force_index => force_index)
    end
    HadoopInstance.find_each do |hadoop_instance|
      hadoop_instance.refresh
    end
    Rails.logger.info("Solr Refresh Completed")
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