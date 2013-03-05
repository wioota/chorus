class DatasetDownloadsController < StreamsController
  include DataSourceAuth

  def show
    dataset = Dataset.find(params[:dataset_id])
    stream_options = params.slice(:row_limit, :header).reverse_merge(header: true)
    stream(dataset, current_user, stream_options)
  end
end
