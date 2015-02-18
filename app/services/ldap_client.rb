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
                  "Could not authenticate with user #{username} in #{config['user']['search_base']} using filter #{config['user']['filter']}"
              )
      end

      if config['group']['search_base'].present? && !user_in_user_group?(user_entries.first)
        raise LdapCouldNotFindMember.new(
                  "Could not find membership for #{user_entries.first.dn} "\
                  "in group base #{config['group']['search_base']} with filter #{config['group']['filter']}"
              )
      end

      user_entries.first
    end
  end

  # looks for Group DN in User entry
  def reverse_membership_lookup(user_entry, group_entries, ldap)
    group_search_filter = config['group']['filter']

    # The inject block builds up a string of membership filters which are OR'd together to make the filter
    membership_filters = group_entries.inject("") { |result, group_entry| result + "#{group_search_filter.gsub("{0}", group_entry.dn)}" }
    complete_filter = "(|#{membership_filters})"

    results = ldap.search :base => user_entry.dn, :filter => complete_filter
    return results.present?
  end

  # looks for User DN in Group entries
  def full_membership_lookup(user_entry, group_entries, ldap)
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

      return reverse_membership_lookup(user_entry, group_entries, ldap) || full_membership_lookup(user_entry, group_entries, ldap)
    end

    return false
  end

  def client
    raise LdapNotEnabled.new unless enabled?

    ldap_args = {:host => config['host'], :port => config['port'], :base => "DC=alpinenow,DC=local", :auth => {:method => :anonymous}}
    if config['bind'].present?
      ldap_args[:auth] = {:method => :simple, :username => config['bind']['username'], :password => config['bind']['password']}
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
