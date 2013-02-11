class DatasetColumnPresenter < Presenter
  include DbTypesToChorus

  def to_hash
    {
      :name => model.name,
      :data_type => model.data_type,
      :type_category => type_category,
      :description => model.description,
      :statistics => statistics,
      :entity_type => model.entity_type_name
    }
  end

  def type_category
    to_category(model.data_type)
  end

  def statistics
    return { } unless model.statistics.present?
    present(model.statistics)
  end

  def complete_json?
    true
  end
end