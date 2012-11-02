require_relative("../lib/properties")

config = Properties.load_file("config/chorus.properties")
puts config['postgres_port']

