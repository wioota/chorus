require 'dataset'

class GpdbView < Dataset
  attr_accessible :query

  belongs_to :schema, :class_name => 'GpdbSchema', :counter_cache => :active_tables_and_views_count

  after_update :update_counter_cache

  def verify_in_source(user)
    schema.connect_as(user).view_exists?(name)
  end
end