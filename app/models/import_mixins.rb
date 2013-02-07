module ImportMixins
  extend ActiveSupport::Concern

  def workspace_is_not_archived
    if workspace && workspace.archived?
      errors.add(:workspace, "Workspace cannot be archived for import.")
    end
  end

  # should probably talk to the database to figure this out instead of use our local view
  def table_does_not_exist
    return true unless to_table
    exists = table_exists?
    errors.add(:base, :table_exists, {:table_name => to_table}) if exists
    !exists
  end

  def table_exists?
    return unless user
    return @_table_exists if instance_variable_defined?(:@_table_exists)

    @_table_exists = sandbox.connect_as(user).table_exists?(to_table)
  end

  def table_does_exist
    return true unless to_table
    exists = table_exists?
    errors.add(:base, :table_not_exists, {:table_name => to_table}) unless exists
    exists
  end

  def tables_have_consistent_schema
    return unless to_table && table_exists?
    dest = sandbox.datasets.find_by_name(self.to_table)
    if dest && !self.source_dataset.dataset_consistent?(dest)
      errors.add(:base,
                 :table_not_consistent,
                 {:src_table_name => source_dataset.name,
                  :dest_table_name => to_table}
      )
    end
  end

  def find_destination_dataset
    sandbox.datasets.tables.find_by_name(to_table)
  end

  def set_destination_dataset_id
    self.destination_dataset = find_destination_dataset
  end

  included do
    belongs_to :workspace

    validates :workspace, :presence => true
    validate :destination_dataset, :unless => :new_table

    belongs_to :destination_dataset, :class_name => 'Dataset'
    before_validation :set_destination_dataset_id

    delegate :sandbox, :to => :workspace
  end

  def source_dataset_with_deleted
    Dataset.unscoped.find(source_dataset_id)
  end

  def workspace_with_deleted
    Workspace.unscoped.find(workspace_id)
  end

end