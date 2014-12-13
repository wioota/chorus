json.actor do
  json.id actor.id
  json.username actor.username
  json.first_name actor.first_name
  json.last_name  actor.last_name
  json.image do
    if actor.image_file_name == nil
      json.original '/images/default-user-icon.png'
      json.icon  '/images/default-user-icon.png'
    else
      json.original actor.image_file_name
      json.icon actor.image_file_name
    end
    if actor.image_content_type == nil
      json.entity_type 'image'
    else
      json.entity_type actor.image_content_type
    end
    json.complete_json true
  end
end