class UserPresenter < Presenter

  def to_hash
    if rendering_activities?
      {
          :id => model.id,
          :username => model.username,
          :first_name => model.first_name,
          :last_name => model.last_name,
          :image => present(model.image)
      }
    else
      {
          :id => model.id,
          :username => model.username,
          :first_name => model.first_name,
          :last_name => model.last_name,
          :email => model.email,
          :title => model.title,
          :dept => model.dept,
          :notes => model.notes,
          :admin => model.admin?,
          :image => present(model.image)
      }
    end
  end

  def complete_json?
    !rendering_activities?
  end
end
