class AlpineWorkfileValidator < ActiveModel::Validator
  def validate(record)
    ensure_single_database(record)
    ensure_no_chorus_views(record)
    ensure_active_workspace(record)
    ensure_single_hdfs_data_source(record)
  end

  def ensure_single_database(record)
    record_datasets_map = record.datasets.map(&:database)
    record.errors[:datasets] << :too_many_databases unless record_datasets_map.uniq.count <= 1
  end

  def ensure_no_chorus_views(record)
    record.errors[:datasets] << :chorus_view_selected if record.datasets.map(&:type).include?("ChorusView")
  end

  def ensure_active_workspace(record)
    record.errors[:workspace] << :ARCHIVED if record.workspace && record.workspace.archived?
  end

  def ensure_single_hdfs_data_source(record)
    record_hdfs_entries_map = record.hdfs_entries.map(&:hdfs_data_source)
    record.errors[:hdfs_entries] << :too_many_hdfs_data_sources unless record_hdfs_entries_map.uniq.count <= 1
  end
end
