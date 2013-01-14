class DataSourcesController < GpdbController
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
    created_gpdb_instance = current_user.gpdb_instances.create!(params[:gpdb_instance], :as => :create)
    QC.enqueue_if_not_queued("GpdbInstance.refresh", created_gpdb_instance.id, 'new' => true)

    present created_gpdb_instance, :status => :created
  end

  def update
    gpdb_instance = GpdbInstance.find(params[:id])
    authorize! :edit, gpdb_instance
    gpdb_instance.update_attributes!(params[:gpdb_instance])
    present gpdb_instance
  end
end
