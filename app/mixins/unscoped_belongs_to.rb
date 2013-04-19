module UnscopedBelongsTo
  extend ActiveSupport::Concern

  module ClassMethods
    def unscoped_belongs_to(name, options = {})
      scoped_name = "scoped_#{name}".to_sym
      foreign_key = options[:foreign_key] || "#{name}_id".to_sym
      klass = options[:class_name].try(:constantize) || name.to_s.camelize.constantize
      new_opts = options.merge :foreign_key => foreign_key, :class_name => klass
      belongs_to scoped_name, new_opts

      define_method name do
        unscoped_getter scoped_name, foreign_key, klass
      end

      define_method "#{name}=".to_sym do |value|
        send "#{scoped_name}=".to_sym, value
      end
    end
  end

  def unscoped_getter(scoped_name, foreign_key, klass)
    begin
      value = send scoped_name
      unless value
        value = klass.unscoped.find(send foreign_key)
        send "#{scoped_name}=", value
      end
      value
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end