class DatasetImportSchedulesController < ApplicationController
  wrap_parameters :dataset_import_schedule, :exclude => [:id]

  def index
    import_schedules = ImportSchedule.where(
        :workspace_id => params[:workspace_id],
        :source_dataset_id => params[:dataset_id]
    )
    present import_schedules, :presenter_options => {:dataset_id => params[:dataset_id]}
  end

  def create
    import_params = normalize_attributes(params[:dataset_import_schedule])
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace
    src_table = Dataset.find(params[:dataset_id])
    import_schedule = src_table.import_schedules.new(import_params)
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
    unnormalize_params = params[:dataset_import_schedule]
    import_schedule = ImportSchedule.find(params[:id])
    import_params = normalize_attributes(unnormalize_params)
    authorize! :can_edit_sub_objects, import_schedule.workspace

    if import_schedule.update_attributes(import_params)
      dst_table = import_schedule.workspace.sandbox.datasets.find_by_name(import_schedule[:to_table])

      Events::ImportScheduleUpdated.by(current_user).add(
          :workspace => import_schedule.workspace,
          :source_dataset => import_schedule.source_dataset,
          :dataset => dst_table,
          :destination_table => import_schedule.to_table
      )

      present import_schedule
    else
      raise ApiValidationError.new(import_schedule.errors)
    end
  end

  def destroy
    import_schedule = ImportSchedule.find(params[:id])
    authorize! :can_edit_sub_objects, import_schedule.workspace
    begin
      dst_table = import_schedule.workspace.sandbox.datasets.find_by_name(import_schedule.to_table)
      Events::ImportScheduleDeleted.by(current_user).add(
          :workspace => import_schedule.workspace,
          :source_dataset => import_schedule.source_dataset,
          :dataset => dst_table,
          :destination_table => import_schedule.to_table
      )
      import_schedule.destroy
    rescue Exception => e
      raise ApiValidationError.new(:base, :delete_unsuccessful)
    end

    render :json => {}
  end

  def normalize_attributes(unnormalized_params)
    normalized_params = unnormalized_params
    normalized_params[:frequency] = unnormalized_params[:frequency].downcase if unnormalized_params[:frequency]
    normalized_params[:start_datetime] = DateTime.parse(unnormalized_params[:start_datetime]) if unnormalized_params[:start_datetime]
    normalized_params
  end
end
