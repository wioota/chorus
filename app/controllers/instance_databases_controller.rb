class InstanceDatabasesController < DataSourcesController
  def index
    gpdb_instance = GpdbInstance.find(params[:data_source_id])
    databases = GpdbDatabase.visible_to(authorized_gpdb_account(gpdb_instance))

    present paginate databases
  end

  def show
    database = GpdbDatabase.find(params[:id])
    authorize_gpdb_instance_access(database)
    present database
  end
end
