json.partial! 'dataset', dataset: dataset, options: options
json.object_type 'CHORUS_VIEW'
json.query dataset.query
json.is_deleted !dataset.deleted_at.nil?
