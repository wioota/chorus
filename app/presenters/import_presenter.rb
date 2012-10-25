class ImportPresenter < Presenter

  def to_hash
    {
        :execution_info => {
          :to_table => model.to_table,
          :to_table_id => model.target_dataset_id,
          :started_stamp => model.created_at,
          :completed_stamp => model.finished_at,
          :state => model.state,
          :source_id => model.source_dataset_id,
          :source_table => Dataset.find(model.source_dataset_id).name
        },
        :source_id => model.source_dataset_id,
        :source_table => Dataset.find(model.source_dataset_id).name
    }
  end
end

