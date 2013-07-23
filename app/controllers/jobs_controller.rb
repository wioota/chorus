class JobsController < ApplicationController

  def index
    render json: []
  end

  def create
    Job.create! params[:job]
    head :created
  end
end