class Comment < ActiveRecord::Base
  include SoftDelete
  include Recent
  include SearchableText

  attr_accessible :author_id, :body, :event_id
  belongs_to :event, :class_name => 'Events::Base'
  belongs_to :author, :class_name => 'User'

  validates_presence_of :author_id, :body, :event_id

  searchable_text :body

  delegate :grouping_id, :type_name, :to => :event

  def self.include_shared_search_fields(target_name)
    klass = ModelMap::CLASS_MAP[target_name.to_s]
    define_shared_search_fields(klass.shared_search_fields, :event, :proc => proc { |method_name|
      if event.respond_to? :"search_#{method_name}"
        event.send(:"search_#{method_name}")
      end
    })
  end

  include_shared_search_fields(:workspace)
  include_shared_search_fields(:dataset)

  def self.add_search_permissions(current_user, search)
    [Dataset, Workspace, Workfile].each do |klass|
      klass.add_search_permissions(current_user, search)
    end
  end

  def security_type_name
    event.security_type_name
  end
end
