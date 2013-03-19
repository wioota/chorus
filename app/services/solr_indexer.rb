module SolrIndexer
  def self.refresh_and_reindex(types)
    self.refresh_external_data
    self.reindex(types)
  end

  def self.reindex(types)
    Rails.logger.info("Starting Solr Full Re-Index")
    types_to_index(types).each(&:solr_reindex)
    Sunspot.commit
    Rails.logger.info("Solr Full Re-Index Completed")
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

  def self.reindex_objects(object_identifiers)
    Rails.logger.info("Starting Solr Partial Reindex")
    objects = object_identifiers.map do |ary|
      begin
        klass = ary[0].constantize
        id = ary[1]
        klass.find(id)
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
    objects.compact!
    Sunspot.index objects
    Sunspot.commit
    Rails.logger.info("Solr Partial Reindex Completed")
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