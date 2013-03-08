module Schemas
  class ImportsController < ApplicationController
    wrap_parameters :dataset_import, :exclude => [:id]

    def create
      import_params = params[:dataset_import]
      schema = GpdbSchema.find(params[:schema_id])
      p "Import params ----------> #{import_params}"
      import = schema.imports.new(import_params)
      import.user = current_user
      import.source_dataset = Dataset.find(import_params[:dataset_id])
      p "ABOUT TO SAVE"
      import.save!

      render :json => {}, :status => :created
    end
  end
end