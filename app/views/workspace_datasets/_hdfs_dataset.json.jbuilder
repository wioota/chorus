
json.partial! 'workspace_datasets/dataset', dataset: dataset, options: options
json.file_mask dataset.file_mask
json.partial! 'workspace_datasets/hdfs_datasource', data_source: dataset.hdfs_data_source, options: options
json.object_type 'MASK'
if options[:with_content]
  json.content dataset.contents
end
