module Schemas
  class ImportsController < ApplicationController
    wrap_parameters :dataset_import, :exclude => [:id]

    def create
      import_params = params[:dataset_import]
      import = SchemaImport.new(import_params)
      import.user = current_user
      import.schema = GpdbSchema.find(params[:schema_id])
      import.source_dataset = Dataset.find(import_params[:dataset_id])
      import.save!

      QC.enqueue_if_not_queued("ImportExecutor.run", import.id)
      render :json => {}, :status => :created
    end
  end
end