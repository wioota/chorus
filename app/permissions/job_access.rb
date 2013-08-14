class JobAccess < AdminFullAccess

  def show?(job)
    job.workspace.visible_to?(current_user)
  end
end