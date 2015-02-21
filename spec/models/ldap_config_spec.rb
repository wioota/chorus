require "spec_helper"
require 'fakefs/spec_helpers'

describe LdapConfig do
  include FakeFS::SpecHelpers

  let(:config) { LdapConfig.new }

  describe "an improper configuration" do

    before do
      FileUtils.mkdir_p(Rails.root.join('config').to_s)

    end

    it "should raise an error if any of the required entires are missing" do

      File.open(Rails.root.join('config/ldap.properties').to_s, 'w') do |file|
        new_config = <<-EOF
          # LDAP Settings
          ldap.enable = true
          ldap.port = 389
        EOF
        file << new_config
      end

      expect{ config }.to raise_error(LdapClient::LdapNotCorrectlyConfigured)
    end

    it "should raise an error if one of the mutually dependent entries are missing" do
      File.open(Rails.root.join('config/ldap.properties').to_s, 'w') do |file|
        new_config = <<-EOF
          ldap.enable = true

          ldap.host = localhost
          ldap.port = 389

          ldap.start_tls = false

          ldap.base = DC=alpinenow,DC=local
          ldap.bind.username = CN=Administrator,CN=Users,DC=alpinenow,DC=local
          ldap.bind.password = (password goes here)

          #ldap.group.names = testGroup, otherTestGroup
          ldap.group.search_base = DC=alpinenow,DC=local
          ldap.group.filter = (memberOf={0})

          ldap.user.search_base = CN=Users,DC=alpinenow,DC=local
          ldap.user.filter = (sAMAccountName={0})

          ldap.dn_template = greenplum\{0}

          ldap.attribute.uid = uid
          ldap.attribute.ou = department
          ldap.attribute.gn = givenName
          ldap.attribute.sn = sn
          ldap.attribute.mail = mail
          ldap.attribute.title = title
        EOF
        file << new_config
      end

      # test goes here
      expect{ config }.to raise_error(LdapClient::LdapNotCorrectlyConfigured)
    end

    it "should not raise and error if all of the mutually dependent entries are missing" do

      File.open(Rails.root.join('config/ldap.properties').to_s, 'w') do |file|
        new_config = <<-EOF
          ldap.enable = true

          ldap.host = localhost
          ldap.port = 389

          ldap.start_tls = false

          ldap.base = DC=alpinenow,DC=local
          ldap.bind.username = CN=Administrator,CN=Users,DC=alpinenow,DC=local
          ldap.bind.password = (password goes here)

          #ldap.group.names = testGroup, otherTestGroup
          #ldap.group.search_base = DC=alpinenow,DC=local
          #ldap.group.filter = (memberOf={0})

          ldap.user.search_base = CN=Users,DC=alpinenow,DC=local
          ldap.user.filter = (sAMAccountName={0})

          ldap.dn_template = greenplum\{0}

          ldap.attribute.uid = uid
          ldap.attribute.ou = department
          ldap.attribute.gn = givenName
          ldap.attribute.sn = sn
          ldap.attribute.mail = mail
          ldap.attribute.title = title
        EOF
        file << new_config
      end

      expect{ config }.not_to raise_error
    end

    it "should not raise an error if the enable is false" do

      File.open(Rails.root.join('config/ldap.properties').to_s, 'w') do |file|
        new_config = <<-EOF
          ldap.enable = false

          ldap.host = localhost
          ldap.port = 389

          ldap.start_tls = false

          ldap.base = DC=alpinenow,DC=local
          ldap.bind.username = CN=Administrator,CN=Users,DC=alpinenow,DC=local
          ldap.bind.password = (password goes here)

          ldap.group.names = testGroup, otherTestGroup
          ldap.group.search_base = DC=alpinenow,DC=local
          ldap.group.filter = (memberOf={0})

          ldap.user.search_base = CN=Users,DC=alpinenow,DC=local
          ldap.user.filter = (sAMAccountName={0})

          ldap.dn_template = greenplum\{0}

          ldap.attribute.uid = uid
          ldap.attribute.ou = department
          ldap.attribute.gn = givenName
          ldap.attribute.sn = sn
          ldap.attribute.mail = mail
          ldap.attribute.title = title
        EOF
        file << new_config
      end

      expect{ config }.not_to raise_error
        end

    it "should not raise an error if the configuration is correct" do

      File.open(Rails.root.join('config/ldap.properties').to_s, 'w') do |file|
        new_config = <<-EOF
          ldap.enable = true

          ldap.host = localhost
          ldap.port = 389

          ldap.start_tls = false

          ldap.base = DC=alpinenow,DC=local
          ldap.bind.username = CN=Administrator,CN=Users,DC=alpinenow,DC=local
          ldap.bind.password = (password goes here)

          ldap.group.names = testGroup, otherTestGroup
          ldap.group.search_base = DC=alpinenow,DC=local
          ldap.group.filter = (memberOf={0})

          ldap.user.search_base = CN=Users,DC=alpinenow,DC=local
          ldap.user.filter = (sAMAccountName={0})

          ldap.dn_template = greenplum\{0}

          ldap.attribute.uid = uid
          ldap.attribute.ou = department
          ldap.attribute.gn = givenName
          ldap.attribute.sn = sn
          ldap.attribute.mail = mail
          ldap.attribute.title = title
        EOF
        file << new_config
      end

      expect{ config }.not_to raise_error
    end

  end
end
