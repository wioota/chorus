module SoftDelete
  extend ActiveSupport::Concern
  include UnscopedBelongsTo

  included do
    default_scope :conditions => {:deleted_at => nil}
  end

  def destroy
    run_callbacks(:destroy) do
      self.deleted_at = Time.current.utc
      save(:validate => false)
    end
    self
  end

  def deleted?
    deleted_at.present?
  end

  module ClassMethods
    def find_with_destroyed *args
      self.with_exclusive_scope { find(*args) }
    end
  end

  def unscoped_getter(scoped_name, foreign_key, klass)
    if deleted?
      super
    else
      send scoped_name
    end
  end
end
