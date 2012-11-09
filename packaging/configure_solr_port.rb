require 'yaml'

chorus_home = File.expand_path(File.dirname(__FILE__) + '/../')
require File.join(chorus_home, 'config', 'boot')
require File.join(chorus_home, 'app', 'models', 'chorus_config')
sunspot_yml_path = File.join(chorus_home, 'config', 'sunspot.yml')
sunspot_config = YAML.load_file(sunspot_yml_path)

chorus_config = ChorusConfig.new(chorus_home)
solr_port = chorus_config["solr_port"]

sunspot_config[ENV["RAILS_ENV"]]["solr"]["port"] = solr_port

File.open(sunspot_yml_path, 'w') do |f|
  f.write(YAML.dump(sunspot_config))
end

print solr_port