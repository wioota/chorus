require 'legacy_migration_spec_helper'
require 'fakefs/spec_helpers'

describe ConfigMigrator do
  include FakeFS::SpecHelpers
  let(:properties) { '' }

  let(:input_path) { '/input.properties' }
  let(:output_path) { '/output.properties' }

  let(:options) do
    {
        :output_path => output_path,
        :input_path => input_path
    }
  end
  let(:migrator) { ConfigMigrator.new(options) }

  let(:config_22) { Properties.load_file(output_path) }

  before do
    File.open('/input.properties', 'w') { |f| f << properties }
  end

  describe 'initialize' do
    context 'when output path is not specified' do
      let(:output_path) { nil }

      it "defaults to the default path" do
        migrator.output_path.should == ChorusConfig.config_file_path
      end
    end

    context 'when input path is not specified' do
      let(:input_path) { nil }

      it "raises" do
        expect {
          migrator
        }.to raise_error(ConfigMigrator::MissingOption)
      end
    end
  end

  describe '#migrate' do
    before do
      migrator.migrate
    end

    context 'when there is an existing chorus config' do
      let(:output_path) do
        File.open('/existing.properties', 'w') { |f| f << 'foo=bar' }
        '/existing.properties'
      end

      it 'keeps the options from there' do
        config_22['foo'].should == 'bar'
      end
    end

    describe 'LDAP migration' do
      let(:properties) do
        <<-EOF
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
        EOF
      end
      let(:ldap_config) { config_22['ldap'] }

      it 'contains all fields converted from chorus.properties' do
        ldap_config['enable'].should == false
        ldap_config['host'].should == '10.32.88.212'
        ldap_config['port'].should == 389
        ldap_config['base'].should == 'DC=greenplum,DC=com'
        ldap_config['user_dn'].should == "greenplum\\chorus"
        ldap_config['password'].should == 'secret'
        ldap_config['dn_template'].should == "greenplum\\{0}"

        ldap_config['attribute'].should == {
            'uid' => 'sAMAccountName',
            'ou' => 'department',
            'gn' => 'givenName',
            'sn' => 'sn',
            'cn' => 'cn',
            'mail' => 'mail',
            'title' => 'old title'
        }
      end
    end

    describe 'session timeout migration' do
      # In seconds.
      let(:properties) { 'chorus.ticket.timeout = 7200' }

      it 'migrates' do
        config_22['session_timeout_minutes'].should == 120
      end

      context 'when it is not defined in the 2.1 install' do
        let(:properties) { '' }

        it 'does not blow up' do
          config_22['session_timeout_minutes'].should be_nil
        end
      end
    end

    describe 'sandbox size' do
      let(:sandbox_size) { config_22['sandbox_recommended_size_in_gb'] }

      context 'when no units are given' do
        let(:properties) { 'chorus.sandbox.recommendSize=5' }

        it 'defaults to gigabytes' do
          sandbox_size.should == 5
        end
      end

      context 'when the unit is G' do
        let(:properties) { 'chorus.sandbox.recommendSize=5G' }

        it 'uses gigabytes for the units' do
          sandbox_size.should == 5
        end
      end

      context 'when the unit is M' do
        let(:properties) { 'chorus.sandbox.recommendSize=512M' }

        it 'converts the units to gigabytes' do
          sandbox_size.should == 0.5
        end
      end
    end

    describe 'workfile max size' do
      let(:workfile_max_size) { config_22['file_sizes_mb']['workfiles'] }
      let(:csv_import_max_size) { config_22['file_sizes_mb']['csv_import'] }

      context 'when no units are given' do
        # Defaults to bytes.
        let(:properties) { 'chorus.workfile.max_file_size=1048576' }

        it 'sets the max workfile size in megabytes' do
          workfile_max_size.should == 1
        end

        it 'sets the max CSV upload size in megabytes' do
          csv_import_max_size.should == 1
        end
      end

      context 'when the unit is G' do
        let(:properties) { 'chorus.workfile.max_file_size=1G' }

        it 'sets the max workfile size in megabytes' do
          workfile_max_size.should == 1024
        end

        it 'sets the max CSV upload size in megabytes' do
          csv_import_max_size.should == 1024
        end
      end

      context 'when the unit is M' do
        let(:properties) { 'chorus.workfile.max_file_size=1M' }
        it 'sets the max workfile size in megabytes' do
          workfile_max_size.should == 1
        end

        it 'sets the max CSV upload size in megabytes' do
          csv_import_max_size.should == 1
        end
      end
    end

    describe 'default preview row limit' do
      let(:properties) { 'chorus.workfile.execution.max_rows=100' }
      let(:default_preview_row_limit) { config_22['default_preview_row_limit'] }

      it 'sets the preview row limit' do
        default_preview_row_limit.should == 100
      end
    end

    describe 'execution timeout' do
      let(:properties) { 'chorus.workfile.execution.timeout= 30' } #0.5 minutes
      let(:execution_timeout) { config_22['execution_timeout_in_minutes'] }

      it 'sets the execution timeout for visualizations and workfiles' do
        execution_timeout.should == 0.5
      end
    end
  end
end