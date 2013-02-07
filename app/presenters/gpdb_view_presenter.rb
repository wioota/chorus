class GpdbViewPresenter < DatasetPresenter

  def to_hash
    super.merge(
        :object_type => "VIEW"
    )
  end

  def has_tableau_workbooks?
    true
  end
end
