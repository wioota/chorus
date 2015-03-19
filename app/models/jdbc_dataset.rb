class JdbcDataset < RelationalDataset
  delegate :data_source, :to => :schema

  def column_type
    'JdbcDatasetColumn'
  end

  def inject_overrides
    if @om.nil?
      @om = JdbcOverrides::overrides_by_db_url(data_source.url)
      if !(@om.nil? || @om::DatasetOverrides.nil?)
        self.extend(@om::DatasetOverrides)
        return true
      end
    end

    false
  end

  def after_initialize
    inject_overrides
  end

  def all_rows_sql(limit = nil)
    return all_rows_sql(limit) if inject_overrides

    Arel::Table.new(%("#{schema_name}"."#{name}")).project('*').to_sql
  end
end
