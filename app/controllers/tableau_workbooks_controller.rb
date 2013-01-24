require 'tableau_workbook'
require 'optparse'

class TableauWorkbooksController < ApplicationController
  def create
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace
    dataset = Dataset.find(params[:dataset_id])
    workbook = create_new_workbook(dataset, params[:tableau_workbook][:name],
                                   params[:tableau_workbook][:tableau_username],
                                   params[:tableau_workbook][:tableau_password])

    workfile = nil
    if params[:tableau_workbook][:create_work_file] == "true"
      workfile = LinkedTableauWorkfile.new(file_name: "#{params[:tableau_workbook][:name]}.twb")
      workfile.owner = current_user
      workfile.workspace = workspace
    end

    if (!workfile || workfile.validate_name_uniqueness) && workbook.save
      publication = TableauWorkbookPublication.create!(
          :name => params[:tableau_workbook][:name],
          :dataset_id => dataset.id,
          :workspace_id => params[:workspace_id],
          :project_name => "Default"
      )
      Events::TableauWorkbookPublished.by(current_user).add(
          :workbook_name => publication.name,
          :dataset => publication.dataset,
          :workspace => publication.workspace,
          :workbook_url => publication.workbook_url,
          :project_name => publication.project_name,
          :project_url => publication.project_url
      )
      if workfile
        workfile.tableau_workbook_publication = publication
        workfile.save!

        Events::TableauWorkfileCreated.by(current_user).add(
            :dataset => publication.dataset,
            :workfile => publication.linked_tableau_workfile,
            :workspace => publication.workspace,
            :workbook_name => publication.name
        )
      end
      render :json => {
          :response => {
              :name => publication.name,
              :dataset_id => publication.dataset_id,
              :id => publication.id,
              :url => publication.workbook_url,
              :project_url => publication.project_url
          }
      }, :status => :created
    else
      messages = workbook.errors.full_messages
      messages = messages + workfile.errors.full_messages if workfile
      raise ModelNotCreated.new(messages.join(". "))
    end
  end

  private

  def create_new_workbook(dataset, workbook_name, username, password)
    login_params = {
        :name => workbook_name,
        :server => ChorusConfig.instance['tableau.url'],
        :port => ChorusConfig.instance['tableau.port'],
        :tableau_username => username,
        :tableau_password => password,
        :db_username => dataset.gpdb_data_source.account_for_user!(current_user).db_username,
        :db_password => dataset.gpdb_data_source.account_for_user!(current_user).db_password,
        :db_host => dataset.gpdb_data_source.host,
        :db_port => dataset.gpdb_data_source.port,
        :db_database => dataset.schema.database.name,
        :db_schema => dataset.schema.name}

    if dataset.is_a?(ChorusView)
      TableauWorkbook.new(login_params.merge!(:query => dataset.query))
    else
      TableauWorkbook.new(login_params.merge!(:db_relname => dataset.name))
    end
  end
end