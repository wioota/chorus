require_relative 'installer_errors'

class ChorusExecutor
  attr_writer :destination_path, :version

  def initialize(logger)
    @logger = logger
  end

  def exec(command)
    @logger.capture_output("PATH=#{release_path}/postgres/bin:$PATH && #{command}") || raise(InstallerErrors::CommandFailed, command)
  end

  def rake(command)
    exec "cd #{release_path} && RAILS_ENV=production bin/rake #{command}"
  end

  def start_postgres
    @logger.log "starting postgres..."
    chorus_control "start postgres"
  end

  def stop_postgres
    if File.directory? "#{release_path}/postgres"
      @logger.log "stopping postgres..."
      chorus_control "stop postgres"
    end
  end

  def initdb(data_path, database_user)
    exec "initdb --locale=en_US.UTF-8 -D #{data_path}/db --auth=md5 --pwfile=#{release_path}/postgres/pwfile --username=#{database_user}"
  end

  def extract_postgres(package_name)
    exec "tar xzf #{release_path}/packaging/postgres/#{package_name} -C #{release_path}"
  end

  def start_previous_release
    previous_chorus_control "start"
  end

  def stop_previous_release
    previous_chorus_control "stop"
  end

  def import_legacy_schema(legacy_installation_path)
    exec "cd #{release_path} && INSTALL_ROOT=#{@destination_path} CHORUS_HOME=#{release_path} packaging/chorus_migrate -s legacy_database.sql -w #{legacy_installation_path}/chorus-apps/runtime/data"
  end

  def dump_legacy_data
    exec "cd #{release_path} && PGUSER=edcadmin pg_dump -p 8543 chorus -O -f legacy_database.sql"
  end

  def stop_legacy_app(legacy_installation_path)
    legacy_exec legacy_installation_path, "bin/edcsrvctl stop; true"
  end

  def stop_legacy_app!(legacy_installation_path)
    legacy_exec legacy_installation_path, "bin/edcsrvctl stop"
  end

  def start_legacy_postgres(legacy_installation_path)
    legacy_exec legacy_installation_path, "(bin/edcsrvctl start || bin/edcsrvctl start)"
  end

  private

  def release_path
    "#{@destination_path}/releases/#{@version}"
  end

  def legacy_exec(legacy_installation_path, command)
    exec "cd #{legacy_installation_path} && source #{legacy_installation_path}/edc_path.sh && #{command}"
  end

  def chorus_control(command)
    exec "CHORUS_HOME=#{release_path} #{release_path}/packaging/chorus_control.sh #{command}"
  end

  def previous_chorus_control(command)
    exec "CHORUS_HOME=#{@destination_path}/current #{@destination_path}/chorus_control.sh #{command}"
  end
end