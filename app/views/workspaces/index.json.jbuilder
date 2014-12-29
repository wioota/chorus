json.response do
  json.array! @workspaces do |workspace|
    json.cache! [current_user.id, workspace], expires_in: 2.days do
      json.partial! 'shared/workspace', workspace: workspace, user: current_user
    end
  end
end
