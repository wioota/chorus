class DatabaseSchemasController < ApplicationController
  include DataSourceAuth

  def index
    database = GpdbDatabase.find(params[:database_id])
    schemas = GpdbSchema.visible_to(authorized_account(database), database)
    present paginate schemas
  end
end