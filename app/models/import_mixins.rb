module ImportMixins
  extend ActiveSupport::Concern

  def workspace_is_not_archived
    if workspace && workspace.archived?
      errors.add(:workspace, "Workspace cannot be archived for import.")
    end
  end

  # should probably talk to the database to figure this out instead of use our local view
  def table_does_not_exist
    exists = table_exists?
    errors.add(:base, :table_exists, {:table_name => to_table}) if exists
    !exists
  end

  def table_exists?
    return unless user
    return @_table_exists if instance_variable_defined?(:@_table_exists)

    account = sandbox.gpdb_instance.account_for_user(user)
    count = sandbox.with_gpdb_connection(account) do |conn|
      count_result = conn.exec_query(<<-SQL)
      SELECT COUNT(*)
      FROM pg_tables
      WHERE schemaname = '#{sandbox.name}' AND tablename = '#{to_table}'
      SQL
      count_result[0]['count']
    end
    @_table_exists = count > 0
  end

  def table_does_exist
    exists = table_exists?
    errors.add(:base, :table_not_exists, {:table_name => to_table}) unless exists
    exists
  end

  def tables_have_consistent_schema
    return unless table_exists?
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
    self.destination_dataset = sandbox.datasets.find_by_name(to_table)
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