class DataSourcesController < GpdbController
  wrap_parameters :data_source, :exclude => []

  def index
    data_sources = if params[:accessible]
                       DataSourceAccess.data_sources_for(current_user)
                     else
                       DataSource.scoped
                     end

    present paginate data_sources
  end

  def show
    data_source = DataSource.find(params[:id])
    present data_source
  end

  def create
    type = params[:data_source].delete(:type)

    if type == "GREENPLUM"
      created_gpdb_instance = current_user.gpdb_instances.create!(params[:data_source], :as => :create)
      QC.enqueue_if_not_queued("GpdbInstance.refresh", created_gpdb_instance.id, 'new' => true)
      present created_gpdb_instance, :status => :created

    elsif type == "ORACLE"
      # clean up #42326927
      params[:data_source][:maintenance_db] = params[:data_source][:db_name]
      created_oracle_instance = current_user.oracle_instances.new(params[:data_source])
      created_oracle_instance.shared = true
      created_oracle_instance.save!

      present created_oracle_instance, :status => :created
    else
      raise ApiValidationError.new(:type, :invalid)
    end
  end

  def update
    data_source = DataSource.find(params[:id])
    authorize! :edit, data_source
    data_source.update_attributes!(params[:data_source])
    present data_source
  end
end
