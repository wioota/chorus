class WorkspaceImport < Import
  belongs_to :workspace
  validates :workspace, :presence => true
  validate :workspace_is_not_archived

  def schema
    workspace.sandbox
  end
end