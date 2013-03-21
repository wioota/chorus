class GnipDataSource < ActiveRecord::Base
  include TaggableBehavior
  include Notable

  attr_accessible :name, :stream_url, :description, :username, :password, :owner
  attr_accessor :highlighted_attributes, :search_result_notes

  validates_presence_of :name, :stream_url, :username, :password, :owner
  validates_length_of :name, :maximum => 64

  validates_with DataSourceNameValidator

  belongs_to :owner, :class_name => 'User'
  has_many :events, :through => :activities
  has_many :activities, :as => :entity

  searchable_model do
    text :name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
    text :description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
  end

  def self.type_name
    'DataSource'
  end
end