class AlpineWorkfileValidator < ActiveModel::Validator
  def validate(record)
    ensure_single_database(record)
    ensure_no_chorus_views(record)
    ensure_active_workspace(record)
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
end
