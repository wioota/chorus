class ImagePresenter < Presenter

  def to_hash
    {
        :original => model.url(:original),
        :icon => model.url(:icon)
    }
  end

  def complete_json?
    true
  end
end

