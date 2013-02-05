class StatisticsController < ApplicationController
  include DataSourceAuth

  def show
    dataset = Dataset.find(params[:dataset_id])
    dataset.add_metadata!(authorized_account(dataset))
    present dataset.statistics
  end
end
