require 'fakefs/spec_helpers'
require 'stringio'
require 'yaml'
require_relative '../../app/models/chorus_config'

describe "configure_solr_port" do
  include FakeFS::SpecHelpers

  let(:root_path) { File.expand_path('../../..', __FILE__) }
  let(:script_path) { File.expand_path('../../../packaging/configure_solr_port.rb', __FILE__) }
  let(:sunspot_config) { File.expand_path('../../../config/sunspot.yml', __FILE__) }
  let(:chorus_config) { ChorusConfig.new(root_path) }

  before do
    @orig_stdout = $stdout
    @original_env, ENV["RAILS_ENV"] = ENV["RAILS_ENV"], "test"
    $stdout = StringIO.new
    FakeFS::FileSystem.clone(root_path + "/config")
  end

  after do
    ENV["RAILS_ENV"] = @original_env
    $stdout = @orig_stdout
  end

  it "returns the solr port from the chorus properties" do
    load script_path
    output.should == chorus_config['solr_port'].to_s
  end

  it "updates sunspot.yml to have the correct port" do
    File.open(root_path + '/config/chorus.properties', 'w') do |f|
      f.puts "solr_port = 1234"
    end
    load script_path
    config = YAML.load_file(sunspot_config)
    config["test"]["solr"]["port"].should == 1234
  end

  def output
    $stdout.string
  end
end