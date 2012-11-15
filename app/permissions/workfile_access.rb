class WorkfileAccess < AdminFullAccess
  def show?(workfile)
    WorkspaceAccess.new(context).can? :show, workfile.workspace
  end
end
