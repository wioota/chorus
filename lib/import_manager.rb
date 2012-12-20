class ImportManager < DelegateClass(Import)
  def started?
    enqueued = QC.default_queue.job_count("ImportExecutor.run", id) >= 1
    finished_at.nil? && !enqueued
  end

  def get_procpid(db, type)
    matcher = "%pipe%_#{created_at.to_i}_#{id}" + (type == :writer ? "_w" : "_r")
    result = db.connect_as(user).fetch("select procpid, current_query from pg_stat_activity where current_query LIKE '#{matcher}%' AND current_query NOT LIKE '%procpid%'")
    if result.count > 1
      raise "Unxpected multiple procpids: #{result.inspect}"
    end
    (result.last || {})[:procpid]
  end

  def reader_procpid
    get_procpid(workspace.sandbox.database, :reader)
  end

  def writer_procpid
    get_procpid(source_dataset.schema.database, :writer)
  end

  def named_pipe
    dir = Pathname.new ChorusConfig.instance['gpfdist.data_dir']
    Dir.glob(dir.join "pipe*_#{created_at.to_i}_#{id}").first
  end
end
