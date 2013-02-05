class ColumnController < ApplicationController
  include DataSourceAuth


  def index
    dataset = Dataset.find(params[:dataset_id])
    present paginate GpdbColumn.columns_for(authorized_account(dataset), dataset)
  end
end
