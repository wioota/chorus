class ImportPresenter < Presenter

  def to_hash
    {
        :id => model.id,
        :to_table => model.to_table,
        :destination_dataset_id => model.destination_dataset_id,
        :started_stamp => model.created_at,
        :completed_stamp => model.finished_at,
        :success => model.success,
        :source_dataset_id => model.source_id,
        :source_dataset_name => model.source.try(:name),
        :file_name => model.file_name,
        :workspace_id => model.workspace_id,
        :entity_type => model.entity_type_name
    }
  end
end

