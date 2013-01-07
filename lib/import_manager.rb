class ImportManager < DelegateClass(Import)
  def started?
    started_at.present?
  end

  def procpid_sql(type)
    matcher = "%pipe%_#{created_at.to_i}_#{id}" + (type == :writer ? "_w" : "_r")

    <<-SQL
      SELECT procpid
      FROM pg_stat_activity
      WHERE current_query LIKE '#{matcher}%'
      AND current_query NOT LIKE '%procpid%'
    SQL
  end

  def database(type)
    type == :reader ? workspace.sandbox.database : source_dataset.schema.database
  end

  def busy?(type)
    database(type).connect_as(user).fetch(procpid_sql(type)).any?
  end

  def source_dataset
    Dataset.unscoped {
      __getobj__.source_dataset
    }
  end

  def named_pipe
    return unless ChorusConfig.instance.gpfdist_configured?
    dir = Pathname.new ChorusConfig.instance['gpfdist.data_dir']
    Dir.glob(dir.join "pipe*_#{created_at.to_i}_#{id}").first
  end
end
