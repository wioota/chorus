require 'dataset'

class GpdbTable < GpdbDataset
  belongs_to :schema, :class_name => 'GpdbSchema', :counter_cache => :active_tables_and_views_count

  after_update :update_counter_cache

  def analyze(account)
    schema.connect_with(account).analyze_table(name)
  end


  def verify_in_source(user)
    schema.connect_as(user).table_exists?(name)
  end
end
