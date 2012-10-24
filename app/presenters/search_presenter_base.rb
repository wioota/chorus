class SearchPresenterBase < Presenter

  def present_workspace_models_with_highlights(models)
    present_models_with_highlights(models, :workspace => model.workspace)
  end

  def present_models_with_highlights(models, options = {})
    models.collect do |model|
      m = (model.is_a? Workfile) ? model.latest_workfile_version : model
      hsh = present(m, options)

      hsh[:highlighted_attributes] = model.highlighted_attributes
      hsh[:comments] = model.search_result_notes
      hsh[:entity_type] = model.entity_type_name
      if hsh[:entity_type] == 'dataset'
        extend_result_with_nested_highlights(hsh)
      end
      hsh
    end
  end

  def complete_json?
    true
  end

  private

  def extend_result_with_nested_highlights(result)
    schema_name = result[:highlighted_attributes].delete(:schema_name)
    result[:schema][:highlighted_attributes] = {:name => schema_name} if schema_name

    database_name = result[:highlighted_attributes].delete(:database_name)
    result[:schema][:database][:highlighted_attributes] = {:name => database_name} if database_name

    object_name = result[:highlighted_attributes].delete(:name)
    result[:highlighted_attributes][:object_name] = object_name if object_name

    column_name = result[:highlighted_attributes].delete(:column_name)
    result[:columns] = column_name.map { |name| { :highlighted_attributes => { :body => name } } } if column_name

    column_description = result[:highlighted_attributes].delete(:column_description)
    result[:column_descriptions] = column_description.map { |desc| { :highlighted_attributes => { :body => desc } } } if column_description

    table_description = result[:highlighted_attributes].delete(:table_description)
    result[:table_description] = [{:highlighted_attributes => {:body => table_description}}] if table_description
  end
end