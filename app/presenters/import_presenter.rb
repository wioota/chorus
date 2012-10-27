class ImportPresenter < Presenter

  def to_hash
    hash = {
        :execution_info => {
          :to_table => model.to_table,
          :to_table_id => model.target_dataset_id,
          :started_stamp => model.created_at,
          :completed_stamp => model.finished_at,
          :state => model.state,
          :source_id => model.source_dataset_id,
          :file_name => model.file_name
        },
        :source_id => model.source_dataset_id,
    }

    dataset = Dataset.find_by_id(model.source_dataset_id)

    if dataset
      hash[:execution_info][:source_table] = dataset.name
      hash[:source_table] = dataset.name
    end

    hash
  end
end

