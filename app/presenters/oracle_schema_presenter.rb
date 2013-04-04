class OracleSchemaPresenter < Presenter
  def to_hash
    {
      :id => model.id,
      :name => model.name,
      :dataset_count => model.active_tables_and_views_count,
      :entity_type => "oracle_schema",
      :instance => present(model.data_source, options),
      :refreshed_at => model.refreshed_at
    }
  end
end