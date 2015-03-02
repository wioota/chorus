require 'net/ldap'

module LdapClient
  LdapNotEnabled = Class.new(StandardError)
  LdapNotCorrectlyConfigured = Class.new(StandardError)
  LdapCouldNotBindWithUser = Class.new(StandardError)
  LdapCouldNotFindMember = Class.new(StandardError)
  extend self

  def enabled?
    config.fetch('enable', false)
  end

  # used to prefill a user create form
  def search(username)

    return [] if username.nil?

    if LdapConfig.exists?
      filter = config['user']['filter'].gsub('{0}', username)
      results = client.search :filter => filter
    else
      filter = Net::LDAP::Filter.eq(config['attribute']['uid'], username)
      results = client.search :filter => filter
    end

    unless results
      error = client.get_operation_result
      Rails.logger.error "LDAP Error: settings are mis-configured"
      raise LdapNotCorrectlyConfigured.new("LDAP settings are mis-configured. Please contact your System Administrator")
    end

    begin
      handle_group_membership(results.first, username) unless results.empty?
    rescue LdapClient::LdapCouldNotFindMember
      results = [] # unfortunate workaround to get frontend to show correct error message
    end

    results.map do |result|
      user_hash = {
        :username =>   result[config['attribute']['uid']].first,
        :dept =>       result[config['attribute']['ou']].first,
        :first_name => result[config['attribute']['gn']].first,
        :last_name =>  result[config['attribute']['sn']].first,
        :email =>      result[config['attribute']['mail']].first,
        :title =>      result[config['attribute']['title']].first,
        :auth_method => 'ldap'
      }

      user_group_names = config['group']['names'].split(',').map(&:strip).first if config['group']
      user_hash[:ldap_group_id] =  user_group_names if user_group_names.present?

      user_hash
    end
  end



  def fetch_members(groupname)

    users = []

    begin
      filter = Net::LDAP::Filter.eq 'cn', groupname
      if config['group']['search_base'] == nil
        puts 'You must specify a valid search base in ldap.group.search_base property of ldap.properties file'
        return
      end
      group_search_base = config['group']['search_base']
      group_entries = client.search :base => group_search_base, :filter => filter
      if group_entries == nil || group_entries.size == 0
        puts 'No members are found in LDAP group #{groupname}'
        return
      end
      group_entries.each do |entry|
        #get member list from group
        members = entry.member

        members.each do |member|
          #puts "#{member}"
          # use DN as search base to fetch attributes for a given
          results = client.search :base => member

          results.map do |result|
            entry = {}
            entry[:username] =   result[config['attribute']['uid']].first.strip
            entry[:dept] =       result[config['attribute']['ou']].first
            entry[:first_name] = result[config['attribute']['gn']].first
            entry[:last_name] =  result[config['attribute']['sn']].first
            entry[:email] =      result[config['attribute']['mail']].first
            entry[:title] =      result[config['attribute']['title']].first
            entry[:auth_method] = 'ldap'
            entry[:ldap_group_id] = groupname
            entry[:admin] = false

            users << entry

          end

        end

      end

      return users

    rescue => e
      puts 'Error executing rake task ldap:import_users'
      puts "#{e.class} :  #{e.message}"
      raise e
    end

  end

  # used to login to Chorus as an LDAP user. First if-block is for backwards-compatibility
  def authenticate(username, password)
    ldap = client

    if !LdapConfig.exists?

      ldap = client
      ldap.auth make_dn(username), password
      return ldap.bind

    else

      if !ldap.bind
        error = ldap.get_operation_result
        Rails.logger.error "LDAP Error: Code: #{error.code} Message: #{error.message}"
        raise LdapNotCorrectlyConfigured.new(error.message)
      end

      user_entries = ldap.bind_as(
        :base => config['user']['search_base'],
        :filter => config['user']['filter'].gsub('{0}', username),
        :password => password
      )

      if !user_entries
        raise LdapCouldNotBindWithUser.new(
                  "Could not authenticate with user #{username} in #{config['user']['search_base']}"
              )
      end

      handle_group_membership(user_entries.first, username)

      user_entries.first
    end
  end

  # Fetch list of users from a specified LDAP group and add them to Chorus users table. In order to authenticate with LDAP
  # we are required to create those users in Chorus database.

  def add_users_to_chorus(groupname)

    license = License.instance
    dev_licenses = license[:developers]

    begin
      dev_users = User.where({:auth_method => 'ldap', :developer => true}).count
      if dev_licenses != -1 && dev_users >= dev_licenses
        puts "You have reached the limit of #{dev_licenses} developer licenses. Please delete existing user(s) before adding new users.\n OR Contact Alpine support to increase the number of licenses."
        return
      end
      if config['group']['names'] == nil
        puts 'You must specify a  valid group name in ldap.group.names property of ldap.properties file'
        return
      end
      groups = config['group']['names'].split(',').map(&:strip)
      if groups == nil || groups.size ==0
        puts 'You must specify a  valid group name in ldap.group.names property of ldap.properties file'
        return
      end
      groups.each do |group|
        users = fetch_members(group)
        if users == nil || users.size == 0
          puts "No members are found in LDAP group #{group}"
          return
        end
        users.each do |user|

          begin

            if User.find_by_username(user[:username])
              u = User.find_by_username(user[:username])
              puts "Updating user #{user[:username]} to Chorus"
              u.update_attributes!(user)
            else
              if dev_licenses != -1 && dev_users >= dev_licenses
                puts "You have reached the limit of #{dev_licenses} developers licenses. Please delete existing user(s) before adding new users.\n OR Contact Alpine support to increase the number of licenses."
                return
              end
              puts "Adding user #{user[:username]} to Chorus"
              #puts user.inspect
              u = User.new(user)
              u.developer = true
              u.save!
              dev_users = dev_users+1
            end

          rescue ActiveRecord::RecordInvalid => e
            puts "\nUnable to add user #{user[:username]}"
            puts "Check attribute names in ldap.properties"
            puts e.message
            puts
          end
        end
      end
    rescue => e
      raise e
    end
  end


  # looks for Group DN in User entry
  def reverse_membership_lookup(user_entry, group_entries, ldap)
    return false if group_entries.nil? || group_entries.empty?
    group_search_filter = config['group']['filter']

    # The inject block builds up a string of membership filters which are OR'd together to make the filter
    membership_filters = group_entries.inject("") { |result, group_entry| result + "#{group_search_filter.gsub("{0}", group_entry.dn)}" }
    complete_filter = "(|#{membership_filters})"

    results = ldap.search :base => user_entry.dn, :filter => complete_filter
    return results.present?
  end

  # looks for User DN in Group entries
  def full_membership_lookup(user_entry, group_entries, ldap)
    return false if group_entries.nil? || group_entries.empty?
    group_search_filter = config['group']['filter']

    group_entries.each do |group_entry| # if we find a group, see if our user_dn is a member of that group
      filter = "#{group_search_filter.gsub('{0}', user_entry.dn)}"
      results = ldap.search :base => group_entry.dn, :filter => filter
      return true if results.present?
    end
    return false
  end

  # This method must support both reverse membership lookups and
  # full membership lookups in order to support different implementations
  # of LDAP
  def user_in_user_group?(user_entry)
    ldap = client
    group_search_base = config['group']['search_base']
    user_group_names = config['group']['names'].split(',').map(&:strip)

    user_group_names.each do |group_cn| # search for each group name in the LDAP tree
      filter = Net::LDAP::Filter.eq 'cn', group_cn

      # There may be many groups with the same CN but different DNs. We need to check them all
      group_entries = ldap.search :base => group_search_base, :filter => filter

       if reverse_membership_lookup(user_entry, group_entries, ldap) || full_membership_lookup(user_entry, group_entries, ldap)
         return true
       end
    end

    return false
  end

  def client
    raise LdapNotEnabled.new unless enabled?

    if LdapConfig.exists? # Using new config structure

      ldap_args = {:host => config['host'], :port => config['port'], :base => config['base'], :auth => {:method => :anonymous}}
      if config['bind'].present?
        ldap_args[:auth] = {:method => :simple, :username => config['bind']['username'], :password => config['bind']['password']}
      end
      ldap_args[:encryption] = :start_tls if config['start_tls'].present?

    else # supporting old config structure for backwards compatibility

      ldap_args = {:host => config['host'], :port => config['port'], :base => config['base'], :auth => {:method => :anonymous}}
      if config['user_dn'].present?
        ldap_args[:auth] = {:method => :simple, :username => config['user_dn'], :password => config['password']}
      end
      ldap_args[:encryption] = :start_tls if config['start_tls'].present?
    end


    Net::LDAP.new ldap_args
  end

  private

  def handle_group_membership(entry, username)
    if config['group'].present? && !user_in_user_group?(entry)
      raise LdapCouldNotFindMember.new(
              "No entry found for user #{username} in LDAP group #{config['group']['names']}. Please contact your system administrator"
            )
    end
  end

  def make_dn(username)
    config['dn_template'].gsub('{0}', username)
  end

  def config
    if LdapConfig.exists?
      LdapConfig.instance['ldap'] || {}
    else
      ChorusConfig.instance['ldap'] || {}
    end
  end
end
