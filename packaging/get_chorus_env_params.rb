script_dir = File.expand_path(File.dirname(__FILE__))


print 'POSTGRES_PORT="'
load "#{script_dir}/get_postgres_port.rb"
puts '"'

print 'SOLR_PORT="'
load "#{script_dir}/get_solr_port.rb"
puts '"'

print 'CHORUS_JAVA_OPTIONS="'
load "#{script_dir}/get_full_java_options.rb"
puts '"'

print 'CHORUS_JAVA_OPTIONS_WITHOUT_XMS="'
load "#{script_dir}/get_java_options_without_xms.rb"
puts '"'