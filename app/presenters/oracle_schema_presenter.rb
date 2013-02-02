class OracleSchemaPresenter < Presenter
  def to_hash
    {
      :id => model.id,
      :name => model.name,
      :entity_type => "oracle_schema"
    }
  end
end