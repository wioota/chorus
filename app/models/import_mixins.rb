module ImportMixins
  extend ActiveSupport::Concern

  def workspace_is_not_archived
    if workspace && workspace.archived?
      errors.add(:workspace, "Workspace cannot be archived for import.")
    end
  end

  # should probably talk to the database to figure this out instead of use our local view
  def table_does_not_exist
    table = sandbox.datasets.find_by_name(to_table)
    errors.add(:base, :table_exists, {:table_name => to_table}) if table
  end

  def table_does_exist
    table = sandbox.datasets.find_by_name(to_table)
    errors.add(:base, :table_not_exists, {:table_name => to_table}) unless table
  end

  def tables_have_consistent_schema
    dest = sandbox.datasets.find_by_name(self.to_table)
    if dest && !self.source_dataset.dataset_consistent?(dest)
      errors.add(:base,
                 :table_not_consistent,
                 {:src_table_name => source_dataset.name,
                  :dest_table_name => to_table}
      )
    end
  end

  def set_destination_dataset_id
    self.destination_dataset = sandbox.datasets.find_by_name(to_table) unless destination_dataset
  end

  included do
    belongs_to :workspace

    validates :workspace, :presence => true
    validate :destination_dataset, :unless => :new_table

    belongs_to :destination_dataset, :class_name => 'Dataset'
    before_validation :set_destination_dataset_id

    delegate :sandbox, :to => :workspace
  end
end