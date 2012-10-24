class UserPresenter < Presenter

  def to_hash
    if rendering_activities?
      {
          :id => model.id,
          :username => h(model.username),
          :first_name => h(model.first_name),
          :last_name => h(model.last_name),
          :image => present(model.image)
      }
    else
      {
          :id => model.id,
          :username => h(model.username),
          :first_name => h(model.first_name),
          :last_name => h(model.last_name),
          :email => h(model.email),
          :title => h(model.title),
          :dept => h(model.dept),
          :notes => h(model.notes),
          :admin => model.admin?,
          :image => present(model.image)
      }
    end
  end

  def complete_json?
    !rendering_activities?
  end
end
