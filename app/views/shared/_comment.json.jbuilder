json.id comment.id
json.partial! 'shared/user', user: comment.author, title: 'author'
json.body comment.body
json.action 'SUB_COMMENT'
json.timestamp comment.created_at
json.entity_type comment.entity_type_name
