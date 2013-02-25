class DatasetDownloadsController < StreamsController
  include DataSourceAuth

  def show
    dataset = Dataset.find(params[:dataset_id])
    stream(dataset, current_user, params[:row_limit], params[:header])
  end
end
