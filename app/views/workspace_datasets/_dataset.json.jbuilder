json.recent_comments do
  json.array! dataset.most_recent_comments do |comment|
    json.partial! 'shared/comment', comment: comment, user: comment.author
  end
end
json.comment_count dataset.most_recent_comments.size
json.id dataset.id
json.object_name dataset.name
if dataset.schema != nil
  schema_partial = dataset.schema.class.name.underscore
  json.partial! schema_partial, schema: dataset.schema, options: options
end
json.entity_type dataset.entity_type_name
# see DatasetPresenter.subtype method. Need to replicate the logic here
json.entity_subtype "SANDBOX_TABLE"
json.stale dataset.stale?
json.is_deleted dataset.deleted?
json.associated_workspaces do
  json.array!  dataset.bound_workspaces.map do |workspace|
    json.id workspace.id
    json.name workspace.name
  end
end
json.partial! 'workspace_datasets/workspace', workspace: options[:workspace], user: options[:user], options: options

if (options[:rendering_activities] || options[:succinct] || !dataset.is_a?(ChorusView))
  json.has_credentials true
else
  json.has_credentials dataset.accessible_to(user)
end
# Setting tableau_workbooks as it is not yet implemented in current codebase. Prakash 1/2/15
json.tableau_workbooks []
json.partial! 'shared/tags', tags: dataset.tags
json.complete_json true

