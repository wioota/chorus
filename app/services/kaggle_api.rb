class KaggleApi
  def self.users(options = {})
    users = JSON.parse(File.read(Rails.root + "kaggleSearchResults.json")).collect {|data| KaggleUser.new(data)}
    users.select {|user| search_through_filter(user, options[:filters])}
  end

  private

  def self.search_through_filter(user, filters)
    return_val = true
    return return_val if filters.nil?
    filters.each { |filter|
      key, comparator, value = filter.split("|")
      next unless value
      value = URI.decode(value)
      value = value.to_i if value.try(:to_i).to_s == value.to_s
      case comparator
        when 'greater'
          return_val = return_val && (user[key] > value)
        when 'less'
          return_val = return_val && (user[key] < value)
        when 'includes'
          return_val = return_val && (user[key] || '').downcase.include?(value.to_s.downcase)
        else #'equal'
          if key == 'past_competition_types'
            return_val = return_val && (user[key].map(&:downcase).include?(value.downcase))
          else
            return_val = return_val && (user[key] == value)
          end
      end
    }
    return_val
  end
end

class KaggleUser
  def initialize(attributes)
    @data = attributes
  end

  def number_of_entered_competitions
    @data["PastCompetitions"].length
  end

  def [](method_name)
    return @data[method_name] unless METHOD_MAP.stringify_keys.keys.include?(method_name) || method_name == 'number_of_entered_competitions'
    send(method_name.to_sym)
  end

  METHOD_MAP = {
    :id => :UserId,
    :username => :Username,
    :location => :Location,
    :rank  => :KaggleRank,
    :points => :KagglePoints,
    :gravatar_url => :Gravatar,
    :full_name => :LegalName,
    :past_competition_types => :PastCompetitionTypes,
    :favorite_technique => :FavoriteTechnique,
    :favorite_software => :FavoriteSoftware
  }

  METHOD_MAP.each do |key, value|
    define_method(key) do
      @data[value.to_s]
    end
  end
end