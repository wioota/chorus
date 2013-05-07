class DatabasesController < ApplicationController
  include DataSourceAuth

  def index
    gpdb_data_source = GpdbDataSource.find(params[:data_source_id])
    databases = GpdbDatabase.visible_to(authorized_account(gpdb_data_source))

    present paginate databases
  end

  def show
    database = GpdbDatabase.find(params[:id])
    authorize_data_source_access(database)
    present database
  end
end
