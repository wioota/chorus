class SchemasController < ApplicationController
  include DataSourceAuth

  def show
    schema = Schema.find_and_verify_in_source(params[:id], current_user)
    authorize_data_source_access(schema)
    present schema
  end
end
