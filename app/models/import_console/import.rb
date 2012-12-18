class ImportConsole::Import < DelegateClass(Import)
  def started?
    enqueued = QC.default_queue.job_count("ImportExecutor.run", id) >= 1
    finished_at.nil? && !enqueued
  end

  def get_procpid(db, type)
    matcher = "%pipe%_#{id}" + (type == :writer ? "_w" : "_r")
    account = db.gpdb_instance.account_for_user!(user)
    db.with_gpdb_connection(account) do |conn|
      conn.select_value("select procpid from pg_stat_activity where current_query LIKE '#{matcher}%' ORDER BY query_start LIMIT 1")
    end
  end

  def reader_procpid
    get_procpid(workspace.sandbox.database, :reader)
  end

  def writer_procpid
    get_procpid(source_dataset.schema.database, :writer)
  end

  def named_pipe
    dir = Pathname.new ChorusConfig.instance['gpfdist.data_dir']
    Dir.glob(dir.join "pipe*_#{id}").first
  end
end
