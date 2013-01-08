class TagPresenter < Presenter
  def to_hash
    {
        :id => model.id,
        :name => model.name,
        :count => model.taggings_count
    }
  end
end