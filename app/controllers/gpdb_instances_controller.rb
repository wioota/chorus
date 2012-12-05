class GpdbInstancesController < GpdbController
  wrap_parameters :gpdb_instance, :exclude => []

  def index
    gpdb_instances = if params[:accessible]
                       GpdbInstanceAccess.gpdb_instances_for(current_user)
                     else
                       GpdbInstance.scoped
                     end

    present paginate gpdb_instances
  end

  def show
    gpdb_instance = GpdbInstance.find(params[:id])
    present gpdb_instance
  end

  def create
    created_gpdb_instance = Gpdb::InstanceRegistrar.create!(params[:gpdb_instance], current_user)
    QC.enqueue_if_not_queued("GpdbInstance.refresh", created_gpdb_instance.id)

    present created_gpdb_instance, :status => :created
  end

  def update
    gpdb_instance = GpdbInstance.find(params[:id])
    authorize! :edit, gpdb_instance
    updated_gpdb_instance = Gpdb::InstanceRegistrar.update!(gpdb_instance, params[:gpdb_instance], current_user)
    present updated_gpdb_instance
  end
end
