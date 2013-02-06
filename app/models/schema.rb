class Schema < ActiveRecord::Base
  attr_accessible :name, :type
  belongs_to :parent, :polymorphic => true
  has_many :datasets, :foreign_key => :schema_id, :dependent => :destroy


  def self.find_and_verify_in_source(schema_id, user)
    schema = find(schema_id)
    raise ActiveRecord::RecordNotFound unless schema.verify_in_source(user)
    schema
  end

  def verify_in_source(user)
    parent.connect_as(user).schema_exists?(name)
  end

  def connect_as(user)
    connect_with(data_source.account_for_user!(user))
  end

  def refresh_datasets(account, options = {})
    found_datasets = []
    mark_stale = options.delete(:mark_stale)
    force_index = options.delete(:force_index)
    datasets_in_gpdb = connect_with(account).datasets(options)

    datasets_in_gpdb.each do |attrs|
      klass = class_for_type attrs.delete(:type)
      dataset = klass.find_or_initialize_by_name_and_schema_id(attrs[:name], id)
      attrs.merge!(:stale_at => nil) if dataset.stale?
      dataset.assign_attributes(attrs, :without_protection => true)
      begin
        dataset.skip_search_index = true if options[:new]
        if dataset.changed?
          dataset.save!
        elsif force_index
          dataset.index
        end
        found_datasets << dataset
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid, DataSourceConnection::QueryError
      end
    end

    touch(:refreshed_at)

    if mark_stale
      raise "You should not use mark_stale and limit at the same time" if options[:limit]
      (datasets.not_stale - found_datasets).each do |dataset|
        dataset.update_attributes!({:stale_at => Time.current}, :without_protection => true) unless dataset.is_a? ChorusView
      end
    end

    found_datasets
  rescue DataSourceConnection::Error
    touch(:refreshed_at)
    found_datasets
  end
end