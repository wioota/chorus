class ConfigMigrator
  attr_reader :input_path, :output_path

  class MissingOption < StandardError; end

  def self.migrate(options)
    new(options).migrate
  end

  def initialize(options = {})
    @output_path = options[:output_path] || ChorusConfig.config_file_path
    @input_path = options[:input_path]

    raise MissingOption unless @input_path
  end

  def migrate
    @config_21 = Properties.load_file(input_path)
    @config_22 = File.exists?(output_path) ? Properties.load_file(output_path) : {}

    migrate_session_timeout
    migrate_ldap_config
    migrate_sandbox_size
    migrate_workfile_max_size
    migrate_preview_row_limit
    migrate_execution_timeout

    Properties.dump_file(@config_22, output_path)
  end

  private

  def migrate_value(old_key, new_key)
    keys = old_key.split('.')
    old_value = keys.inject(@config_21) do |hash, key|
      hash.fetch(key)
    end

    @config_22[new_key] = block_given? ? yield(old_value) : old_value
  rescue IndexError
  end

  def migrate_execution_timeout
    migrate_value('chorus.workfile.execution.timeout', 'execution_timeout_in_minutes') do |old_value|
      old_value.to_f / 60
    end
  end

  def migrate_preview_row_limit
    migrate_value('chorus.workfile.execution.max_rows', 'default_preview_row_limit')
  end

  def migrate_workfile_max_size
    %w{file_sizes_mb.workfiles file_sizes_mb.csv_import}.each do |key|
      migrate_value('chorus.workfile.max_file_size', key) do |old_value|
        case old_value
          when /G$/ then
            old_value.to_f * 1024
          when /M$/ then
            old_value.to_f
          else
            old_value.to_f / (1024 * 1024)
        end
      end
    end
  end

  def migrate_session_timeout
    migrate_value('chorus.ticket.timeout', 'session_timeout_minutes') { |old_value| old_value/60 }
  end

  def migrate_sandbox_size
    migrate_value('chorus.sandbox.recommendSize', 'sandbox_recommended_size_in_gb') do |old_value|
      if old_value.to_s.match /M$/
        old_value.to_f / 1024
      else
        old_value.to_f
      end
    end
  end

  def migrate_ldap_config
    migrate_value('chorus.ldap.enable', 'ldap.enable')
    migrate_value('chorus.ldap.host', 'ldap.host')
    migrate_value('chorus.ldap.port', 'ldap.port')
    migrate_value('chorus.ldap.base', 'ldap.base')
    migrate_value('chorus.ldap.userDn', 'ldap.user_dn')
    migrate_value('chorus.ldap.password', 'ldap.password')
    migrate_value('chorus.ldap.dn.template', 'ldap.dn_template')

    %w{uid ou gn sn cn mail title}.each do |property|
      migrate_value("chorus.ldap.attribute.#{property}", "ldap.attribute.#{property}")
    end
  end
end
