class AlpineWorkfile < Workfile
  class TooManyDataBases < StandardError; end
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

  has_additional_data :database_id, :dataset_ids

  before_validation { self.content_type ='work_flow' }
  before_validation { self.database_id = datasets.first.database.id unless datasets.empty? }
  validates_presence_of :database_id
  validates_with AlpineWorkfileValidator

  after_destroy :notify_alpine_of_deletion

  def entity_subtype
    'alpine'
  end

  def attempt_data_source_connection
    data_source.connect_as(current_user).connect!
  end

  def data_source
    GpdbDatabase.find(database_id).data_source
  end

  def datasets
    @datasets ||= Dataset.where(:id => dataset_ids)
  end

private

  def notify_alpine_of_deletion
    Alpine::API.delete_work_flow(self)
  end
end