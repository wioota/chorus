require 'dataset'

class GpdbTable < Dataset
  belongs_to :schema, :class_name => 'GpdbSchema', :counter_cache => :active_tables_and_views_count

  after_update :update_counter_cache

  def analyze(account)
    schema.connect_with(account).analyze_table(name)
  rescue Sequel::DatabaseError => e
    if e.message =~ /relation (.*) does not exist/
      relation_name = $1
      raise ActiveRecord::StatementInvalid.new("Dataset (#{relation_name}) does not exist anymore")
    else
      raise ActiveRecord::ActiveRecordError.new(e.message)
    end
  end
end
