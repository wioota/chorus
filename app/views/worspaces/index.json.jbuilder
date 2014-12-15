json.response do
  json.array! @workspaces do |workspace|
    json.cache! [current_user.username, workspace], expires_in: 2.days do
      json.id workspace.id
      json.name workspace.name
      json.entity_type "workspace"
      json.is_deleted workspace.deleted?
      json.summary workspace.summary
      json.archived_at workspace.archived_at
      json.permission workspace.permissions_for(current_user)
      json.public workspace.public
      #json.datasets_count workspace.dataset_count(current_user)
      json.members_count workspace.members.size
      json.workfiles_count workspace.workfiles.size
      json.insights_count workspace.owned_notes.where(:insight => true).count
      json.recent_insights_count workspace.owned_notes.where(:insight => true).recent.count
      json.recent_comments_count workspace.owned_notes.recent.count
      json.has_recent_comments workspace.owned_notes.recent.count > 0
      json.has_milestones workspace.milestones_count > 0
      json.partial! 'shared/user', :user => workspace.owner, :title => 'owner'
    end

  end
end
