class AuroraProviderPresenter < Presenter

  def to_hash
    {
        :install_succeed => model.valid?,
        :templates => present(model.templates)
    }
  end
end
