json.data_source do
  json.partial! 'data_source', data_source: data_source, options: options
  json.is_deleted data_source.deleted_at.nil?
  json.data_source_provider data_source.data_source_provider
  json.complete_json true
end