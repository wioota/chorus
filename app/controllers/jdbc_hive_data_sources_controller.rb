class JdbcHiveDataSourcesController < ApplicationController

  before_filter :demo_mode_filter, :only => [:create, :update, :destroy]
  before_filter :require_data_source_create, :only => [:create]

  def create
    data_source = JdbcHive::DataSourceRegistrar.create!(params[:jdbc_hive_data_source], current_user)
    present data_source, :status => :created
  end

  def index
    succinct = params[:succinct] == 'true'
    includes = succinct ? [] : [{:owner => :tags}, :tags]
    present paginate(JdbcHiveDataSource.scoped.includes(includes)), :presenter_options => {:succinct => succinct}
  end

  def show
    present JdbcHiveDataSource.find(params[:id])
  end

  def update
    gnip_params = params[:jdbc_hive_data_source]
    data_source = JdbcHiveDataSource.find(params[:id])
    authorize! :edit, data_source
    data_source = JdbcHive::DataSourceRegistrar.update!(params[:id], gnip_params)

    present data_source
  end

  def destroy
    data_source = JdbcHiveDataSource.find(params[:id])
    authorize! :edit, data_source
    data_source.destroy

    head :ok
  end
end
