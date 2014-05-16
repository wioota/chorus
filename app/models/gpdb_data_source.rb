class GpdbDataSource < ConcreteDataSource
  include PostgresLikeDataSourceBehavior

  has_many :databases, :foreign_key => 'data_source_id', :class_name => 'GpdbDatabase'
  has_many :schemas, :through => :databases
  has_many :datasets, :through => :schemas

  has_many :imports_as_source, :through => :datasets, :source => :imports
  has_many :imports_as_destination_via_schema, :through => :schemas, :source => :imports
  has_many :imports_as_destination_via_workspace, :through => :schemas, :source => :imports_via_workspaces
  has_many :workspaces, :through => :schemas, :foreign_key => 'sandbox_id'

  def self.create_for_user(user, data_source_hash)
    user.gpdb_data_sources.create!(data_source_hash, :as => :create)
  end

  def used_by_workspaces(viewing_user)
    workspaces.includes({:sandbox => {:scoped_parent => :data_source }}, :owner).workspaces_for(viewing_user).order("lower(workspaces.name), id")
  end

  def data_source_provider
    'Greenplum Database'
  end

  private

  def cancel_imports
    imports_as_source.unfinished.each do |import|
      import.cancel(false, "Source/Destination of this import was deleted")
    end
    imports_as_destination_via_schema.unfinished.each do |import|
      import.cancel(false, "Source/Destination of this import was deleted")
    end
    imports_as_destination_via_workspace.unfinished.each do |import|
      import.cancel(false, "Source/Destination of this import was deleted")
    end
  end

  def connection_class
    GreenplumConnection
  end
end
