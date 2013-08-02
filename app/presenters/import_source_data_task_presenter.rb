class ImportSourceDataTaskPresenter < JobTaskPresenter

  def to_hash
    super.merge!(model.additional_data).merge({
                                                :source_name => model.source_dataset.name,
                                                :destination_name => model.destination_dataset_name
                                              })
  end

end