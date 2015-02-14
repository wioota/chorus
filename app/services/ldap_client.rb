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
    filter = Net::LDAP::Filter.eq(config['attribute']['uid'], username)
    results = client.search :filter => filter

    unless results
      error = client.get_operation_result
      Rails.logger.error "LDAP Error: Code: #{error.code} Message: #{error.message}"
      raise LdapNotCorrectlyConfigured.new(error.message)
    end

    results.map do |result|
      {
        :username =>   result[config['attribute']['uid']].first,
        :dept =>       result[config['attribute']['ou']].first,
        :first_name => result[config['attribute']['gn']].first,
        :last_name =>  result[config['attribute']['sn']].first,
        :email =>      result[config['attribute']['mail']].first,
        :title =>      result[config['attribute']['title']].first
      }
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

      user_entries = ldap.bind_as(
        :base => config['user_search_base'],
        :filter => config['user_search_filter'].gsub('{0}', username),
        :password => password
      )

      if !user_entries
        raise LdapCouldNotBindWithUser.new(
                  "Could not authenticate with user #{username} in #{config['user_search_base']} using filter #{config['user_search_filter']}"
              )
      end


      if config['group_search_base'].present? && !user_dn_in_user_group?(user_entries.first.dn)
        raise LdapCouldNotFindMember.new(
                  "Could not find membership for #{user_entries.first.dn} "\
                  "in group base #{config['group_search_base']} with filter #{config['group_search_filter']}"
              )
      end

      user_entries.first
    end
  end

  def user_dn_in_user_group?(user_dn)
    ldap = client

    group_search_base = config['group_search_base']
    group_search_filter = config['group_search_filter'] # TODO: try to use group_search_filter, revert to

    user_groups = config['user_groups'].split(',').map(&:strip)

    if ldap.bind

      user_groups.each do |group_cn| # search for each group name in the LDAP tree

        filter = Net::LDAP::Filter.eq 'cn', group_cn
        results = ldap.search :base => group_search_base, :filter => filter

        results.each do |group| # if we find a group, see if our user_dn is a member of that group
          return true if group[:member].any?{|dn| dn.casecmp(user_dn)}
        end
      end

      return false
    else
      error = ldap.get_operation_result
      Rails.logger.error "LDAP Error: Code: #{error.code} Message: #{error.message}"
      raise LdapNotCorrectlyConfigured.new(error.message)
    end
  end

  def create_users
    ldap = client
    ldap.search(:base => "ou=" + config["attribute"]["ou"] + "," + config["base"]) do |entry| # add a config option for this
      create_user_from_entry entry
    end
  end

  def create_user_from_entry(entry)
    User.create! ( {
        :username =>   entry[config['attribute']['uid']].first,
        :dept =>       entry[config['attribute']['ou']].first,
        :first_name => entry[config['attribute']['gn']].first,
        :last_name =>  entry[config['attribute']['sn']].first,
        :email =>      entry[config['attribute']['mail']].first,
        :title =>      entry[config['attribute']['title']].first
    })
  end

  def client
    raise LdapNotEnabled.new unless enabled?

    ldap_args = {:host => config['host'], :port => config['port'], :base => config['base'], :auth => {:method => :anonymous}}
    if config['user_dn'].present?
      ldap_args[:auth] = {:method => :simple, :username => config['user_dn'], :password => config['password']}
    end
    ldap_args[:encryption] = :start_tls if config['start_tls'].present?

    Net::LDAP.new ldap_args
  end

  private

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
