class ImportSchedulePresenter < Presenter

  def to_hash
    {
        :id => (model.id if model.is_active),
        :source_id => model.source_dataset_id,
        :dataset_id => @options[:dataset_id],
        :workspace_id => model.workspace_id,
        :start_datetime => model.start_datetime,
        :end_date => model.end_date,
        :frequency => model.frequency,
        :next_import_at => model.next_import_at,
        :to_table => model.to_table,
        :truncate => model.truncate,
        :sample_count => model.sample_count,
        :destination_dataset_id => model.target_dataset_id,
        :new_table => model.new_table,
        :last_scheduled_at => model.last_scheduled_at,
        :is_active => model.is_active,
    }.merge(execution_info_hash)
  end

  def execution_info_hash
    if @options[:import]
      import = @options[:import]
    else
      import = model.imports.order("created_at asc").last
    end

    if import
      present import
    else
      {:execution_info => {}}
    end
  end

  def complete_json?
    true
  end
end

