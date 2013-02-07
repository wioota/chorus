class GpdbTablePresenter < DatasetPresenter
  def to_hash
    super.merge(:object_type => "TABLE")
  end

  def has_tableau_workbooks?
    true
  end
end