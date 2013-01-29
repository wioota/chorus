class UserPresenter < Presenter

  def to_hash
    results = {
        :id => model.id,
        :username => model.username,
        :first_name => model.first_name,
        :last_name => model.last_name,
        :image => present(model.image),
        :entity_type => model.entity_type_name
    }
    unless rendering_activities?
      results.merge!({
          :email => model.email,
          :title => model.title,
          :dept => model.dept,
          :notes => model.notes,
          :admin => model.admin?
      })
    end

    if options[:include_api_key]
      results[:api_key] = model.api_key
    end
    results
  end

  def complete_json?
    !rendering_activities?
  end
end
