
json.response do
  json.array!(@events) do |event|
    json.id event.id
    json.partial! 'events/actor', actor: event.actor
    json.action event.action
    json.timestamp event.updated_at
    if event.workspace != nil
      json.partial! 'events/workspace', workspace: event.workspace
    end
  end
end
