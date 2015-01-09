
json.hdfs_data_source do
  json.id data_source.id
  json.name data_source.name
  json.entity_type data_source.entity_type_name
  json.supports_work_flows data_source.supports_work_flows
  json.hdfs_version data_source.hdfs_version
  json.is_deleted data_source.deleted?
  json.host data_source.host
  json.port data_source.port
  json.online data_source.online?
  json.description data_source.description
  json.version data_source.version
  json.username data_source.username
  json.group_list data_source.group_list
  json.job_tracker_host data_source.job_tracker_host
  json.job_tracker_port data_source.job_tracker_port
  json.high_availability data_source.high_availability
  # TODO. Need to be completed
  json.connection_parameters data_source.connection_parameters
end