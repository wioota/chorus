class ImportTerminator < DelegateClass(Import)

  def self.terminate(import)
    new(import).terminate
  end

  def self.log(arg)
    Rails.logger.info "ImportTerminator: " + arg
  end

  delegate :log, :to => name.to_sym

  def manager
    @manager ||= ImportManager.new(__getobj__)
  end

  def terminate_process(database, type)
    method = "#{type}_procpid"
    procpid = manager.send(method)
    database_description = "database #{database.name} on instance #{database.gpdb_instance.name}"

    if procpid
      log "Found running #{type} with procpid #{procpid} running on #{database_description}"
      success = database.connect_as(user).fetch("select pg_terminate_backend(#{procpid})")
      log success.first[:pg_terminate_backend] ? "Successfully killed #{type} process" : "Failed to kill #{type} process"
    else
      log "Could not find running #{type} process on database #{database_description}"
    end

    queue_classic_job_unstarted = QC.default_queue.job_count("ImportExecuter.run", id) > 0
    log "Removing unstarted queue classic job" if queue_classic_job_unstarted
  end

  def terminate
    log "Terminating import: #{__getobj__.inspect}"
    terminate_process(source_dataset.schema.database, :writer)
    terminate_process(workspace.sandbox.database, :reader)
    if manager.named_pipe
      log "Removing named pipe #{manager.named_pipe}"
      FileUtils.rm_f manager.named_pipe if manager.named_pipe
    else
      log "No named pipe was found."
    end
  end
end