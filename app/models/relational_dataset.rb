class RelationalDataset < Dataset
  def source_dataset_for(workspace)
    schema_id != workspace.sandbox_id
  end

  def in_workspace?(workspace)
    self.bound_workspaces.include?(workspace) || workspace.sandbox.datasets.include?(self)
  rescue NoMethodError
    false
  end

  def associable?
    true
  end
end