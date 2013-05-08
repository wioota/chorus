require "spec_helper"
require 'fakefs/spec_helpers'

describe ChorusConfig do
  include FakeFS::SpecHelpers

  let(:config) { ChorusConfig.new }
  before do
    FileUtils.mkdir_p(Rails.root.join('config').to_s)
    File.open(Rails.root.join('config/chorus.properties').to_s, 'w') do |file|
      new_config = <<-EOF
        parent.child=yes
        simple=no
      EOF
      file << new_config
    end

    File.open(Rails.root.join('config/chorus.defaults.properties').to_s, 'w') do |file|
      new_config = <<-EOF
        simple= yes!
        a_default= maybe
      EOF
      file << new_config
    end

    File.open(Rails.root.join('config/secret.key').to_s, 'w') do |file|
      file << "secret_key_goes_here\n"
    end
  end

  it "reads the chorus.properties file" do
    config['simple'].should == 'no'
  end

  it "reads the secret.key file" do
    config['secret_key'].should == "secret_key_goes_here"
  end

  it "reads composite keys" do
    config['parent'].should == {'child' => 'yes'}
    config['parent.child'].should == 'yes'
  end

  it "falls back on values from chorus.defaults.properties" do
    config['a_default'].should == 'maybe'
  end

  it "returns nil on an undefined key" do
    config['undefined.key'].should == nil
  end

  describe "#tableau_configured?" do
    let(:tableau_config) do
      {
          'enabled' => true,
          'url' => 'localhost',
          'port' => 1234
      }
    end

    it 'returns true if the tableau url/port are configured' do
      config.config = {'tableau' => tableau_config}
      config.tableau_configured?.should == true
    end

    it 'returns false if the enabled flag is false but all the others are present' do
      disabled_config = tableau_config.merge({'enabled' => false})
      config.config = {'tableau' => disabled_config}
      config.tableau_configured?.should == false
    end

    it 'returns false if any of the keys are missing' do
      tableau_config.each do |key, _value|
        invalid_config = tableau_config.reject { |attr, _value| attr == key }
        config.config = {'tableau' => invalid_config}
        config.tableau_configured?.should == false
      end
    end

    it 'returns false if the enabled key is undefined' do
      tableau_config.delete('enabled')
      config.config = {'tableau' => tableau_config}
      config.tableau_configured?.should == false
    end
  end

  describe "#kaggle_configured?" do
    let(:kaggle_config) do
      {
          'enabled' => true,
          'api_key' => "kaggle_api_key"
      }
    end

    context "when the kaggleSearchResults.json exists" do
      before do
        dir = Rails.root.join('demo_data')
        FileUtils.mkdir_p(dir.to_s)
        File.open(dir.join('kaggleSearchResults.json').to_s, 'w') do |f|
          f << "Hello, World!"
        end
      end

      it "returns true" do
        config.config.delete('kaggle')
        config.kaggle_configured?.should be_true
      end

      it "returns true even if the enabled flag is false" do
        config.config = {'kaggle' => kaggle_config.merge('enabled' => false)}
        config.kaggle_configured?.should be_true
      end
    end

    context "when the kaggleSearchResults.json does not exist" do
      it 'returns true if the kaggle url/port and username/password are configured' do
        config.config = {'kaggle' => kaggle_config}
        config.kaggle_configured?.should be_true
      end

      it 'returns false if the enabled flag is false' do
        disabled_config = kaggle_config.merge({'enabled' => false})
        config.config = {'kaggle' => disabled_config}
        config.kaggle_configured?.should be_false
      end

      it 'returns false if either config is missing' do
        kaggle_config.each do |key, _value|
          invalid_config = kaggle_config.reject { |attr, _value| attr == key }
          config.config = {'kaggle' => invalid_config}
          config.should_not be_kaggle_configured
        end
      end

      it 'returns false if the enabled key is undefined' do
        kaggle_config.delete('enabled')
        config.config = {'kaggle' => kaggle_config}
        config.kaggle_configured?.should be_false
      end
    end
  end

  describe "#gnip_configured?" do
    it 'returns true if the gnip.enabled key is there' do
      config.config = {
          'gnip' => {
              'enabled' => true
          }
      }
      config.gnip_configured?.should == true
    end

    it 'returns false if the gnip.enabled value is false' do
      config.config = {
          'gnip' => {
              'enabled' => false
          }
      }
      config.gnip_configured?.should == false
    end

    it 'returns false if the enabled key is undefined' do
      config.config = {}
      config.gnip_configured?.should == false
    end
  end

  describe "#alpine_configured?" do
    it 'returns true if alpine.url and alpine.api_key are set' do
      config.config = {
          'alpine' => {
              'url' => 'test',
              'api_key' => 'key'
          }
      }
      config.alpine_configured?.should == true
    end

    it 'returns false if the alpine.url is not set' do
      config.config = {
          'alpine' => {
              'url' => '',
              'api_key' => 'key'
          }
      }
      config.alpine_configured?.should == false
    end

    it 'returns false if the alpine.api_key is not set' do
      config.config = {
          'alpine' => {
              'url' => 'test',
              'api_key' => ''
          }
      }
      config.alpine_configured?.should == false
    end

    it 'returns false if the enabled key is undefined' do
      config.config = {}
      config.alpine_configured?.should == false
    end
  end

  describe "Data Science Studio integration" do
    let(:data_science_studio_config) do
      {
        'enabled' => true,
        'url' => 'localhost'
      }
    end

    describe "data_science_studio_configured?" do
      before do
        config.config = {'data_science_studio' => data_science_studio_config}
      end

      context "when enabled is true and url is provided" do
        it "is true" do
          config.data_science_studio_configured?.should be_true
        end
      end

      context "when url is provided and enabled is false" do
        let(:data_science_studio_config) do
          {
              'url' => 'localhost',
              'enabled' => false
          }
        end

        it "is false" do
          config.data_science_studio_configured?.should be_false
        end
      end

      context "when enabled is true but url is not provided" do
        let(:data_science_studio_config) do
          {
              'enabled' => true
          }
        end

        it "is false" do
          config.data_science_studio_configured?.should be_false
        end
      end
    end


  end

  describe "oracle configuration" do
    let(:enabled) {false}
    before do
      config.config = {
          'oracle' => {
              'enabled' => enabled
          }
      }
    end
    context "if the jar file exists" do
      before do
        dir = Rails.root.join('lib','libraries')
        FileUtils.mkdir_p(dir.to_s)
        File.open(dir.join('ojdbc6.jar').to_s, 'w') do |f|
          f << "Hello, World!"
        end
      end

      context 'oracle.enabled key is true' do
        let(:enabled) {true}
        specify { config.oracle_configured?.should == true }
        specify { config.oracle_driver_expected_but_missing?.should == false }
      end

      context 'oracle.enabled key is false' do
        let(:enabled) {false}
        specify { config.oracle_configured?.should == false }
        specify { config.oracle_driver_expected_but_missing?.should == false }
      end
    end

    context "if the jar file does not exist" do
      context 'oracle.enabled key is true' do
        let(:enabled) {true}
        specify { config.oracle_configured?.should == false }
        specify { config.oracle_driver_expected_but_missing?.should == true }
      end

      context 'oracle.enabled key is false' do
        let(:enabled) {false}
        specify { config.oracle_configured?.should == false }
        specify { config.oracle_driver_expected_but_missing?.should == false }
      end
    end
  end

  describe "#log_level" do
    it 'returns info for invalid values of loglevel' do
      config.config = {
          'logging' => {
              'loglevel' => 'pandemic'
          }
      }
      config.log_level.should == :info
    end

    it 'returns info for undefined values of loglevel' do
      config.config = {}
      config.log_level.should == :info
    end

    it "symbolizes valid levels" do
      config.config = {
          'logging' => {
              'loglevel' => 'debug'
          }
      }
      config.log_level.should == :debug
    end
  end

  describe "#syslog_configured?" do
    it 'returns true if the logger.syslog.enabled key is there' do
      config.config = {
          'logging' => {
              'syslog' => {
                  'enabled' => true
              }
          }
      }
      config.syslog_configured?.should be_true
    end

    it 'returns false if the logger.syslog.enabled value is false' do
      config.config = {
          'logging' => {
              'syslog' => {
                  'enabled' => false
              }
          }
      }
      config.should_not be_syslog_configured
    end
  end

  describe "#gpfdist_configured?" do
    it "returns true if all the gpfdist keys are set" do
      config.config = {
          'gpfdist' => {
              'url' => 'localhost',
              'write_port' => 8181,
              'read_port' => 8180,
              'data_dir' => '/tmp',
              'ssl' => {
                  'enabled' => false
              }
          }
      }
      config.gpfdist_configured?.should == true
    end

    it "returns false if any of the gpfdist keys are missing" do
      ['url', 'write_port', 'read_port', 'data_dir', 'ssl'].each do |gpfdist_key|
        config.config = {
            'gpfdist' => {
                'url' => 'localhost',
                'write_port' => 8181,
                'read_port' => 8180,
                'data_dir' => '/tmp',
                'ssl' => {
                    'enabled' => false
                }
            }
        }
        config.config['gpfdist'].delete(gpfdist_key)
        config.should_not be_gpfdist_configured
      end
    end
  end

  describe "#server_port" do
    context "when ssl is enabled" do
      before do
        config.config = {
            'server_port' => 4567,
            'ssl_server_port' => 1234,
            'ssl' => {
                'enabled' => true
            }
        }
      end

      it "returns the ssl server port" do
        config.server_port.should == 1234
      end
    end

    context "when ssl is disabled" do
      before do
        config.config = {
            'server_port' => 4567,
            'ssl_server_port' => 1234,
            'ssl' => {
                'enabled' => false
            }
        }
      end

      it "returns the ssl server port" do
        config.server_port.should == 4567
      end
    end
  end

  describe "#public_url" do
    before do
      config.config = {
          'public_url' => 'example.com',
      }
    end

    it "returns the public url" do
      config.public_url.should == 'example.com'
    end
  end
end
