class GpdbSchemaFunctionPresenter < Presenter

  def to_hash
    {
        :schema_name => model.schema_name,
        :name => model.function_name,
        :language => model.language,
        :return_type => model.return_type,
        :arg_names => model.arg_names,
        :arg_types => model.arg_types,
        :definition => model.definition,
        :description => model.description
    }
  end

  def complete_json?
    true
  end
end