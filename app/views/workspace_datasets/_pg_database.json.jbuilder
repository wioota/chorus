json.database do
  json.id database.id
  json.name database.name
  ds_partial = database.data_source.class.name.underscore
  json.partial! ds_partial, data_source: database.data_source, options: options
  json.entity_type database.entity_type_name
  json.complete_json true
end