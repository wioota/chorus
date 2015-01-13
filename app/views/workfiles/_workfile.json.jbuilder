
recent_comments = Array.wrap(workfile.recent_comment)
json.id workfile.id
json.workspace do
  json.partial! 'workspaces/workspace', workspace: workfile.workspace, user: current_user, options: options
end
json.file_name workfile.file_name
json.file_type workfile.content_type
json.latest_version_id workfile.latest_workfile_version_id
json.is_deleted workfile.deleted?
json.recent_comments Presenter.present(recent_comments, :as_comment => true)
json.comment_count recent_comments.size
json.tags Presenter.present(workfile.tags, options)
json.entity_type workfile.entity_type_name
json.entity_subtype workfile.entity_subtype
json.user_modified_at workfile.user_modified_at
json.status workfile.status
json.partial! 'shared/user', user: workfile.owner, title: 'owner', options: options
json.has_draft workfile.has_draft(current_user)
json.execution_schema Presenter.present(workfile.execution_schema, options.merge(:succinct => options[:list_view]))
json.version_info do
  json.partial! 'workfile_versions/workfile_version', workfile_version: workfile.latest_workfile_version, options: options
end
json.complete_json true
