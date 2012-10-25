class Comment < ActiveRecord::Base
  include SoftDelete
  include Recent
  include SearchableHtml
  include SharedSearch

  attr_accessible :author_id, :body, :event_id
  belongs_to :event, :class_name => 'Events::Base'
  belongs_to :author, :class_name => 'User'

  validates_presence_of :author_id, :body, :event_id

  searchable_html :body
  searchable do
    string :grouping_id
    string :type_name
  end

  delegate :grouping_id, :type_name, :to => :event
  delegate_search_permissions_for :workspace, :dataset, :to => :event
end
