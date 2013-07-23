class JobsController < ApplicationController
  def index
    workspace = {id: params[:workspace_id]}
    render json: {response:
                      [
                          {id: 1, name: "zname1", workspace: workspace, state: "running", next_run: 24.hours.from_now, frequency: "weekly", last_run: 24.hours.ago},
                          {id: 2, name: "name2", workspace: workspace, state: "scheduled", next_run: 500.hours.from_now, frequency: "daily", last_run: nil},
                          {id: 3, name: "name3", workspace: workspace, state: "disabled", next_run: nil, frequency: "monthly", last_run: 11.hours.ago},
                          {id: 4, name: "name4", workspace: workspace, state: "running", next_run: nil, frequency: "on_demand", last_run: 8.hours.ago},
                          {id: 5, name: "name5", workspace: workspace, state: "scheduled", next_run: 1000.hours.from_now, frequency: "weekly", last_run: nil},
                          {id: 6, name: "aname6", workspace: workspace, state: "disabled", next_run: nil, frequency: "on_demand", last_run: 2.hours.ago}
                      ].sort_by { |job| job[params[:order].to_sym] || Time.now }
    }
  end

  def create
    Job.create! params[:job]
    head :created
  end
end