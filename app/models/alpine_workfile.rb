class AlpineWorkfile < Workfile
  class TooManyDataBases < StandardError; end
  class AlpineWorkfileValidator < ActiveModel::Validator
    def validate(record)
      ensure_single_database(record)
      ensure_no_chorus_views(record)
    end

    def ensure_single_database(record)
      record_datasets_map = record.datasets.map(&:database)
      record.errors[:datasets] << :too_many_databases unless record_datasets_map.uniq.count <= 1
    end

    def ensure_no_chorus_views(record)
      record.errors[:datasets] << :chorus_view_selected if record.datasets.map(&:type).include?("ChorusView")
    end
  end

  has_additional_data :database_id, :dataset_ids

  before_validation { self.content_type ='work_flow' }
  before_validation { self.database_id = datasets.first.database.id unless datasets.empty? }
  validates_presence_of :database_id
  validates_with AlpineWorkfileValidator

  def entity_subtype
    'alpine'
  end

  def datasets
    @datasets ||= Dataset.where(:id => dataset_ids)
  end
end