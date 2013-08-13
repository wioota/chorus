class JobResultsController < ApplicationController
  def show
    job_result = FactoryGirl.create(:job_result)
    present job_result
  end
end