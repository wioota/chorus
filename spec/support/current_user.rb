module CurrentUserHelpers
  def set_current_user(user)
    Thread.current[:user] = user
  end
end