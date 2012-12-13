module Stale
  extend ActiveSupport::Concern

  included do
    scope :not_stale, where(:stale_at => nil)
  end

  def stale?
    stale_at.present?
  end

  def mark_stale!
    touch :stale_at unless stale?
  end
end