require 'dataset'

class GpdbTable < Dataset
  belongs_to :schema, :class_name => 'GpdbSchema', :counter_cache => :active_tables_and_views_count

  after_update :update_counter_cache

  def analyze(account)
    table_name = '"' + schema.name + '"."'  + name + '"';
    query_string = "analyze #{table_name}"
    schema.with_gpdb_connection(account) do |conn|
      conn.exec_query(query_string)
    end
    []
  end
end
