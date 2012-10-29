class DatasetImportSchedulesController < ApplicationController
  def index
    import_schedules = ImportSchedule.where(
        :workspace_id => params[:workspace_id],
        :source_dataset_id => params[:dataset_id]
    )
    present import_schedules, :presenter_options => {:dataset_id => params[:dataset_id]}
  end

  def create
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace
    src_table = Dataset.find(params[:dataset_id])

    import_schedule = src_table.import_schedules.new(params)
    import_schedule.workspace    = workspace
    import_schedule.user         = current_user

    if import_schedule.save
      import_schedule.create_import_event
      present import_schedule
    else
      raise ApiValidationError.new(import_schedule.errors)
    end
  end

  def update
    import_schedule = ImportSchedule.find(params[:id])
    authorize! :can_edit_sub_objects, import_schedule.workspace

    if import_schedule.update_attributes(params)
      import_schedule.create_import_event
      present import_schedule
    else
      raise ApiValidationError.new(import_schedule.errors)
    end
  end

  def destroy
    import_schedule = ImportSchedule.find(params[:id])
    authorize! :can_edit_sub_objects, import_schedule.workspace

    import_schedule.destroy
    render :json => {}
  end
end
