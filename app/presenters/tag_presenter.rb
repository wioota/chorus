class TagPresenter < Presenter
  def to_hash
    {
        :name => model.name
    }
  end
end