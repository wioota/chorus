class OracleSchemaPresenter < Presenter
  def to_hash
    {
      :id => model.id,
      :name => model.name,
      :entity_type => "oracle_schema",
      :instance => present(model.data_source)
    }
  end
end