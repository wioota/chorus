module Workspaces
  class CsvImportsController < ApplicationController
    wrap_parameters :csv_import, :exclude => []

    def create
      csv_file = CsvFile.find params[:csv_id]
      authorize! :create, csv_file

      file_params = params[:csv_import].slice(:types, :delimiter, :column_names, :has_header)
      csv_file.update_attributes!(file_params)

      import_params = params[:csv_import].slice(:to_table, :truncate, :new_table).merge(:csv_file => csv_file, :workspace_id => params[:workspace_id], :user => current_user)
      CsvImport.create!(import_params)
      present [], :status => :created
    end

    private

    def create_import_event(csv_file)
      schema = csv_file.workspace.sandbox
      Events::FileImportCreated.by(csv_file.user).add(
          :workspace => csv_file.workspace,
          :dataset => schema.datasets.tables.find_by_name(csv_file.to_table),
          :file_name => csv_file.contents_file_name,
          :import_type => 'file',
          :destination_table => csv_file.to_table
      )
    end
  end
end