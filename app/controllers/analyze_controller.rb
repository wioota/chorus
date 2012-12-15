class AnalyzeController < GpdbController
  def create
    dataset = Dataset.find(params[:table_id])
    dataset.analyze(authorized_gpdb_account(dataset))
    present([], :status => :ok)
  end
end