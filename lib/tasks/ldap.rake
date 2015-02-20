namespace :ldap do

  desc 'This task will import the users from a LDAP group into Chorus database. It will use the LDAP configuration from the ldap.properties file'
  ENV['SKIP_SOLR'] = 'true'
  task :import_users, [:group] => :environment do |task, args|
    #print "arg = #{args[:group]}\n"
    #print "arg = #{args.extras}\n"
    begin
      LdapClient.add_users_to_chorus(args[:group])
    rescue => e
      puts 'Error executing rake task ldap:import_users'
      puts "#{e.class} :  #{e.message}"
    end

  end

end
