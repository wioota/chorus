class ImportSourceDataTaskPresenter < JobTaskPresenter

  def to_hash
    hash = super.merge!(model.additional_data)
  end

end