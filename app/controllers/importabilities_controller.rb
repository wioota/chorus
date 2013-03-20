class ImportabilitiesController < ApplicationController
  def show
    dataset = Dataset.find(params[:dataset_id])

    if dataset.importable?
      json_hash = {:response => {
        :importability => dataset.importable?
      }}
    else
      json_hash = {:response => {
        :importability => dataset.importable?,
        :invalid_columns => dataset.unimportable_columns,
        :supported_columns => Dataset.supported_column_types
      }}
    end

    render :json => json_hash
  end
end