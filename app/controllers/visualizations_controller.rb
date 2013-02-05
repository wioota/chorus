class VisualizationsController < ApplicationController
  include DataSourceAuth

  wrap_parameters :chart_task

  def create
    dataset = Dataset.find(params[:dataset_id])
    v = Visualization.build(dataset, params[:chart_task])
    v.fetch!(authorized_account(dataset.schema.database), params[:chart_task][:check_id] + "_#{current_user.id}")
    present v
  end

  def destroy
    dataset = Dataset.find(params[:dataset_id])
    instance_account = authorized_account(dataset)
    SqlExecutor.cancel_query(dataset, instance_account, params[:id] + "_#{current_user.id}")
    head :ok
  end
end
