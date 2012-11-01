require_relative("../lib/properties")

config = Properties.load_file("#{File.dirname(__FILE__)}/../config/chorus.properties")
puts config['postgres_port']

