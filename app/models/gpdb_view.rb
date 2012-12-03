require 'dataset'

class GpdbView < Dataset
  belongs_to :schema, :class_name => 'GpdbSchema', :counter_cache => :active_tables_and_views_count

  after_update :update_counter_cache
end