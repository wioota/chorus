class ConfigMigrator < AbstractMigrator
  attr_accessor :properties_path, :output_path, :defaults_path

  def initialize
    @output_path = ChorusConfig.config_file_path
  end

  def migrate
    return if not @properties_path
    Properties.write_file(config, @output_path)
  end

  def config
    config_from_defaults_file.merge(config_from_properties_file)
  end

  def config_from_properties_file
    properties_file_hash = Properties.load_file(@properties_path)
    {
      "ldap" => ldap_config_22(properties_file_hash)
    }
  end

  def config_from_defaults_file
    Properties.load_file(defaults_path)
  end

  def ldap_config_22(hash)
    ldap_config = hash["chorus"]["ldap"]
    {
      "host"              => ldap_config["host"],
      "enable"            => ldap_config["enable"],
      "port"              => ldap_config["port"],
      "connect_timeout"   => ldap_config["connect"]["timeout"],
      "bind_timeout"      => ldap_config["bind"]["timeout"],
      "search"            => {
        "timeout"    => ldap_config["search"]["timeout"],
        "size_limit" => ldap_config["search"]["sizeLimit"]
      },
      "base"              => ldap_config["base"],
      "user_dn"           => ldap_config["userDn"],
      "password"          => ldap_config["password"],
      "dn_template"       => ldap_config["dn"]["template"],
      "attribute"         => {
        "uid"   => ldap_config["attribute"]["uid"],
        "ou"    => ldap_config["attribute"]["ou"],
        "gn"    => ldap_config["attribute"]["gn"],
        "sn"    => ldap_config["attribute"]["sn"],
        "cn"    => ldap_config["attribute"]["cn"],
        "mail"  => ldap_config["attribute"]["mail"],
        "title" => ldap_config["attribute"]["title"]
      }
    }
  end
end
