
json.response do
  json.array!(@events) do |event|
    json.id event.id
    json.partial! 'shared/actor', actor: event.actor
    json.action event.action
    json.timestamp event.updated_at
    if event.workspace != nil
      json.partial! 'shared/workspace', workspace: event.workspace
    end
    json.attachments nil
    json.comments nil
    json.is_insight event.insight
    json.promoted_by event.promoted_by_id
    json.promotion_time event.promotion_time
    json.is_published event.published
    json.complete_json true
  end
end
