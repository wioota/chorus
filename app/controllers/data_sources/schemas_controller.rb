module DataSources
  class SchemasController < ApplicationController
    def index
      data_source = DataSource.find(params[:data_source_id])
      present Schema.visible_to data_source.account_for_user!(current_user), data_source
    end
  end
end