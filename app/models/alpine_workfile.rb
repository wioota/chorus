class AlpineWorkfile < Workfile
  class TooManyDataBases < StandardError; end
  class DataBaseCounter < ActiveModel::Validator
    def validate(record)
      record_datasets_map = record.datasets.map(&:database)
      record.errors[:datasets] << :too_many_databases unless record_datasets_map.uniq.count <= 1
    end
  end

  has_additional_data :database_id, :dataset_ids
  before_validation do
    self.database_id = datasets.first.database.id unless datasets.empty?
  end
  validates_presence_of :database_id
  validates_with DataBaseCounter

  def entity_subtype
    'alpine'
  end

  def datasets
    @datasets ||= Dataset.where(:id => dataset_ids)
  end
end