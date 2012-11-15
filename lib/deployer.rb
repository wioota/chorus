class Deployer
  attr_reader :ssh, :config

  def initialize(config)
    @ssh = Ssh.new(config)
    @config = config
  end

  def deploy(package_file="greenplum-chorus-#{PackageMaker.version_name}.sh")
    upload(package_file)
  end

  def setup_load_test(user_csv_file)
    ssh.copy_up(user_csv_file)
    ssh.run_rake("bulk_data:load_users_from_csv['#{user_csv_file}']")
    ssh.run_rake("db:reset")
    ssh.run_rake("bulk_data:fake_data:load_all['chorusadmin',10,'gpdb42',3]")
  end

  private

  def run(cmd)
    puts cmd
    puts %x{#{cmd}}
    $? == 0
  end

  def install_path
    config['install_path']
  end

  def legacy_path
    config['legacy_path']
  end

  def legacy_data_host
    config['legacy_data_host']
  end

  def postgres_build
    config['postgres_build']
  end

  def clean_install
    config['clean_install']
  end

  def upload(package_file)
    write_install_answers

    remove_previous_chorusrails_install

    # run upgrade script
    installer_dir = "~/chorusrails-installer"
    ssh.run("rm -rf #{installer_dir} && mkdir -p #{installer_dir}")
    ssh.copy_up([package_file, "install_answers.txt"], installer_dir)
    if config['clean_install']
      ssh.chorus_control("stop")
      ssh.run "rm -rf #{install_path}/*"
    end
    ssh.run "cat /dev/null > #{install_path}/install.log" unless legacy_path.present?
    install_success = ssh.run "cd #{installer_dir} && ./#{package_file} #{installer_dir}/install_answers.txt"
    ssh.copy_down("#{install_path}/install.log")
    ssh.run "cd #{installer_dir} && rm -f #{package_file}" # remove installer script from target

    if install_success
      remove_old_builds
      ssh.chorus_control("start")
    end

    raise StandardError.new("Installation failed!") unless install_success
  end

  def remove_previous_chorusrails_install
    if legacy_path.present?
      ssh.chorus_control("stop")
      ssh.run("rm -fr #{install_path}")
      if legacy_data_host
        run "ssh #{legacy_data_host} 'cd #{legacy_path}; source edc_path.sh; PG_USER=edcadmin #{legacy_path}/postgresql/bin/pg_dump -p 8543 chorus -O -f ~/legacy_database.sql'"
        run "scp #{legacy_data_host}:~/legacy_database.sql ."
        run "ssh #{legacy_data_host} 'rm legacy_database.sql'"
        ssh.copy_up("legacy_database.sql", "~")
        ssh.run_in_legacy("cd bin; ./edcsvrctl start")
        ssh.run_in_legacy("PG_USER=edcadmin #{legacy_path}/postgresql/bin/psql -p 8543 chorus -c 'drop schema public cascade'")
        ssh.run_in_legacy("PG_USER=edcadmin #{legacy_path}/postgresql/bin/psql -p 8543 chorus -c 'create schema public'")
        ssh.run_in_legacy("PG_USER=edcadmin #{legacy_path}/postgresql/bin/psql -p 8543 chorus < ~/legacy_database.sql; rm ~/legacy_database.sql")
        run "ssh #{host} 'rsync -avce ssh pivotal@#{legacy_data_host}:#{legacy_path}/chorus-apps/runtime/data/ #{legacy_path}/chorus-apps/runtime/data'"
      end
    end
  end

  def write_install_answers
    File.open('install_answers.txt', 'w') do |f|
      # Accept the EULA
      f.puts("y")

      # where the existing install lives
      if legacy_path.present?
        f.puts(legacy_path)
      else
        f.puts(install_path)
      end

      # confirm the upgrade/install
      f.puts('y') unless clean_install.present?

      # where to install 2.2
      if legacy_path.present?
        f.puts(install_path)
      end

      #give the data directory
      f.puts(install_path + "/shared") if clean_install.present? || legacy_path.present?

      f.puts(postgres_build)

      f.puts("this is a secret passphrase")
    end
  end

  def remove_old_builds(builds_to_keep=5)
    ssh.run "cd #{install_path}/releases && test `ls | wc -l` -gt 5 && find . -maxdepth 1 -not -newer \"`ls -t | head -6 | tail -1`\" -not -name \".\" -exec rm -rf {} \\;"
  end

  class Ssh
    attr_reader :host, :install_path, :legacy_path

    def initialize(deploy_config)
      @host = deploy_config['host']
      @install_path = deploy_config['install_path']
      @legacy_path = deploy_config['legacy_path']
    end

    def copy_up(files, destination_folder="#{install_path}")
      files = Array(files).map { |file| "'#{file}'" }
      execute "scp #{files.join(' ')} #{host}:#{destination_folder}"
    end

    def copy_down(file_path)
      file_name = File.basename(file_path)
      execute "scp #{host}:#{file_path} #{file_name}"
    end

    def run(cmd)
      execute %Q{ssh #{host} "PATH=#{install_path}/current/postgres/bin:$PATH && #{cmd}"}
    end

    def run_rake(rake_task)
      run %Q{cd #{install_path}/current && RAILS_ENV=production bin/rake #{rake_task}}
    end

    def run_in_legacy(cmd)
      run %Q{cd #{legacy_path}; source edc_path.sh; #{cmd}}
    end

    def chorus_control(action)
      run "test -e #{install_path} && CHORUS_HOME=#{install_path}/current #{install_path}/chorus_control.sh #{action}"
    end

    private

    def execute(cmd)
      puts cmd
      puts %x{#{cmd}}
      $? == 0
    end
  end
end