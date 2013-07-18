class AlpineWorkfileValidator < ActiveModel::Validator
  def validate(record)
    ensure_single_execution_location(record)
    ensure_no_chorus_views(record)
  end

  def ensure_single_execution_location(record)
    record_datasets_map = record.datasets.map(&:execution_location)
    record.errors[:datasets] << :too_many_databases unless record_datasets_map.uniq.count <= 1
  end

  def ensure_no_chorus_views(record)
    record.errors[:datasets] << :chorus_view_selected if record.datasets.map(&:type).include?("ChorusView")
  end
end
