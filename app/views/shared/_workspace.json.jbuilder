json.workspace do
  json.id workspace.id
  json.name workspace.name
  if workspace.is_deleted?
    json.is_deleted true
  else
    json.is_deleted false
  end
  json.entity_type "workspace"
  json.summary workspace.summary
  json.archived_at workspace.archived_at
  json.permission "[admin]"
  json.public workspace.public
  json.dataset_count
end
