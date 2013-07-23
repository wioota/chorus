class JobsController < ApplicationController

  def index
    render json: []
  end

  def create
    Job.create!
    head :created
  end
end