module UnscopedBelongsTo
  extend ActiveSupport::Concern

  def unscope_belongs_to(association)
    name = association.name
    new_method = "#{name}_with_unscoped".to_sym
    original_method = "#{name}_without_unscoped".to_sym

    define_method(new_method) do
      association.klass.unscoped { send(original_method) }
    end
    alias_method_chain name, :unscoped
  end

  def belongs_to(name, options = {})
    include_unscoped = options.delete(:unscoped)

    super.tap do |association|
      unscope_belongs_to association if include_unscoped
    end
  end
end