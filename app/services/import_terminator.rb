class ImportTerminator < DelegateClass(Import)

  def self.terminate(import)
    new(import).terminate
  end

  def self.log(arg)
    Rails.logger.info "ImportTerminator: " + arg
  end

  delegate :log, :to => name.to_sym

  def terminate
    log "Terminating import: #{__getobj__.inspect}"
    terminate_process(:writer)
    terminate_process(:reader)
    if manager.named_pipe
      log "Removing named pipe #{manager.named_pipe}"
      FileUtils.rm_f manager.named_pipe if manager.named_pipe
    else
      log "No named pipe was found."
    end
  end

  private

  def manager
    @manager ||= ImportManager.new(__getobj__)
  end

  def terminate_process(type)
    database = manager.database(type)
    database_description = "database #{database.name} on instance #{database.gpdb_instance.name}"

    if manager.busy?(type)
      log "Found running #{type} running on #{database_description}"
      kills = kill(type)

      log "Killed #{kills.count(true)} of #{kills.length} procpids for #{type}"
    else
      log "Could not find running #{type} process on database #{database_description}"
    end
  end

  def kill(type)
    procpids = manager.procpid_sql(type)

    kills = manager.database(type).connect_as(user).fetch(<<-SQL)
      SELECT pg_terminate_backend(procpid)
      FROM (#{procpids}) AS procpids
    SQL
    kills.map {|row| row[:pg_terminate_backend]}
    end

end
