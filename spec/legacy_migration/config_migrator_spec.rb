require 'legacy_migration_spec_helper'
require 'fakefs/spec_helpers'

PROPERTIES = <<EOF
# Enable/disable LDAP
chorus.ldap.enable = false

## Ldap connection setting

# LDAP setting for testing AD server
chorus.ldap.host = 10.32.88.212
chorus.ldap.port = 389
chorus.ldap.connect.timeout = 10000
chorus.ldap.bind.timeout = 10000
chorus.ldap.search.timeout = 20000
chorus.ldap.search.sizeLimit = 200
chorus.ldap.base = DC=greenplum,DC=com
chorus.ldap.userDn = greenplum\\chorus
chorus.ldap.password = secret
chorus.ldap.dn.template = greenplum\\{0}
chorus.ldap.attribute.uid = sAMAccountName
chorus.ldap.attribute.ou = department
chorus.ldap.attribute.gn = givenName
chorus.ldap.attribute.sn = sn
chorus.ldap.attribute.cn = cn
chorus.ldap.attribute.mail = mail
chorus.ldap.attribute.title = old title

ignored = foo
EOF

DEFAULTS = <<EOF
some_key_not_present_in_properties_file = baz
ldap.attribute.title = new default
EOF

describe ConfigMigrator, :legacy_migration => true, :type => :legacy_migration do
  include FakeFS::SpecHelpers
  let(:defaults_file) { '/defaults.properties' }
  let(:properties_file) { '/chorus.properties' }
  let(:output_file) { '/output.properties' }

  before do
    File.open(defaults_file, 'w') { |f| f << DEFAULTS }
    File.open(properties_file, 'w') { |f| f << PROPERTIES }

    @migrator = ConfigMigrator.new
    @migrator.output_path = output_file
    @migrator.defaults_path = defaults_file
    @migrator.properties_path = properties_file

    @migrator.migrate
  end

  let(:config) { Properties.load_file(output_file) }

  it "defaults to the default properties for keys that arent in the properties file" do
    config["some_key_not_present_in_properties_file"].should == "baz"
  end

  describe "the LDAP section" do
    it "should contain all fields converted from chorus.properties" do
      ldap_config = config["ldap"]

      ldap_config["ignored"].should_not be_present

      ldap_config["enable"].should == false
      ldap_config["host"].should == "10.32.88.212"
      ldap_config["port"].should == 389
      ldap_config["connect_timeout"].should == 10000
      ldap_config["bind_timeout"].should == 10000
      ldap_config["base"].should == "DC=greenplum,DC=com"
      ldap_config["user_dn"].should == "greenplum\\chorus"
      ldap_config["password"].should == "secret"
      ldap_config["dn_template"].should == "greenplum\\{0}"

      ldap_config["attribute"].should == {
          "uid" => "sAMAccountName",
          "ou" => "department",
          "gn" => "givenName",
          "sn" => "sn",
          "cn" => "cn",
          "mail" => "mail",
          "title" => "old title"
      }

      ldap_config["search"].should == {
          "timeout" => 20000,
          "size_limit" => 200
      }
    end
  end
end
