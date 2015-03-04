namespace :ldap do

  desc 'This task will import the users from a LDAP group into Chorus database. It will use the LDAP configuration from the ldap.properties file'
  task :import_users, [:group] => :environment do |task, args|
    ENV['SKIP_SOLR'] = 'true'
    #print "arg = #{args[:group]}\n"
    #print "arg = #{args.extras}\n"
    if !LdapConfig.exists?
      puts 'You must configure your ldap.properties file in order to use this rake task.'
      next
    end

    begin
      LdapClient.add_users_to_chorus(args[:group])
    rescue => e
      puts 'Error executing rake task ldap:import_users'
      puts "#{e.class} :  #{e.message}"
    end

    ENV['SKIP_SOLR'] = nil
  end

end
