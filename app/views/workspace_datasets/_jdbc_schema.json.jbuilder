json.schema do
  json.id schema.id
  json.name schema.name
  json.dataset_count schema.active_tables_and_views_count
  json.refreshed_at schema.refreshed_at
  json.entity_type schema.entity_type_name
  json.is_deleted schema.deleted?
  json.stale schema.stale?
  ds_partial = schema.data_source.class.name.underscore
  json.partial! ds_partial, data_source: schema.data_source , options: options
  json.complete_json true
end

