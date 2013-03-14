class DataSourcesController < ApplicationController
  include DataSourceAuth

  wrap_parameters :data_source, :exclude => []

  def index
    succinct = params[:succinct] == 'true'
    includes = succinct ? [] : [{:owner => :tags}, :tags]
    data_sources = DataSource.by_type(params[:entity_type]).includes(includes)
    data_sources = data_sources.accessible_to(current_user) unless params[:all]

    present paginate(data_sources), :presenter_options => {:succinct => succinct}
  end

  def show
    data_source = DataSource.find(params[:id])
    present data_source
  end

  def create
    entity_type = params[:data_source].delete(:entity_type)
    data_source = DataSource.create_for_entity_type(entity_type, current_user, params[:data_source])
    present data_source, :status => :created
  end

  def update
    data_source = DataSource.find(params[:id])
    authorize! :edit, data_source
    data_source.update_attributes!(params[:data_source])
    present data_source
  end
end
