module Alpine
  class DatasetsController < AlpineController
    def index
      datasets = Dataset.includes(Dataset.eager_load_succinct_associations).find(params[:dataset_ids])
      present datasets, :presenter_options => { :succinct => true }
    end
  end
end