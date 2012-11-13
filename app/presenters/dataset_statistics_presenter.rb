class DatasetStatisticsPresenter < Presenter

  def to_hash
    {
        :object_type => model.table_type,
        :rows => model.row_count,
        :columns => model.column_count,
        :description => model.description,
        :last_analyzed_time => model.last_analyzed,
        :on_disk_size => @view_context.number_to_human_size(model.disk_size),
        :partitions => model.partition_count,
        :definition => model.definition
    }
  end

  def complete_json?
    true
  end
end