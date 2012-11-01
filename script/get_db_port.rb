require_relative("../app/models/chorus_config")

config = ChorusConfig.new File.dirname(__FILE__) + "/.." 
puts config['postgres_port']

