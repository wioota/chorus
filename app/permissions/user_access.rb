class UserAccess < AdminFullAccess
  def update?(user)
    user == current_user
  end
end
