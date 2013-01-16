class DataSourcesController < GpdbController
  wrap_parameters :data_source, :exclude => []

  def index
    gpdb_instances = if params[:accessible]
                       DataSourceAccess.data_sources_for(current_user)
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
    type = params[:data_source].delete(:type)

    if type == "GREENPLUM"
      created_gpdb_instance = current_user.gpdb_instances.create!(params[:data_source], :as => :create)
      QC.enqueue_if_not_queued("GpdbInstance.refresh", created_gpdb_instance.id, 'new' => true)
      present created_gpdb_instance, :status => :created

    elsif type == "ORACLE"
      created_oracle_instance = current_user.oracle_instances.create!(params[:data_source])
      present created_oracle_instance, :status => :created
    end
  end

  def update
    data_source = DataSource.find(params[:id])
    authorize! :edit, data_source
    data_source.update_attributes!(params[:data_source])
    present data_source
  end
end
