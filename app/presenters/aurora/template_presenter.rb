module Aurora
  class TemplatePresenter < Presenter

    def to_hash
      {
          :name => model.name,
          :memory_size_in_gb => model.memory_size/1024,
          :vcpu_number => model.vcpu_number
      }
    end
  end
end
