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
    entity_type = params[:data_source].delete(:entity_type)

    if entity_type == "gpdb_data_source"
      created_gpdb_data_source = current_user.gpdb_data_sources.create!(params[:data_source], :as => :create)
      QC.enqueue_if_not_queued("GpdbDataSource.refresh", created_gpdb_data_source.id, 'new' => true)
      present created_gpdb_data_source, :status => :created

    elsif entity_type == "oracle_data_source"
      unless ChorusConfig.instance.oracle_configured?
        raise ApiValidationError.new(:oracle, :not_configured)
      end
      created_oracle_data_source = current_user.oracle_data_sources.new(params[:data_source])
      created_oracle_data_source.shared = true
      created_oracle_data_source.save!

      present created_oracle_data_source, :status => :created
    else
      raise ApiValidationError.new(:entity_type, :invalid)
    end
  end

  def update
    data_source = DataSource.find(params[:id])
    authorize! :edit, data_source
    data_source.update_attributes!(params[:data_source])
    present data_source
  end
end
