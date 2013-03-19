class Tag < ActiveRecord::Base
  has_many :taggables, :through => :taggings
  has_many :taggings

  attr_accessible :name
  attr_accessor :highlighted_attributes, :search_result_notes

  validates_uniqueness_of :name, :case_sensitive => false
  validates_length_of :name, :maximum => 100, :minimum => 1

  after_update :reindex_tagged_objects
  before_destroy do
    reindex_tagged_objects
    taggings.destroy_all
  end

  searchable do
    string :type_name
    text :name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
  end

  def self.named_like(name)
    where(["name ILIKE ?", "%#{name}%"])
  end

  def self.reset_counters
    find_each { |tag| tag.update_attribute(:taggings_count, tag.taggings.count) }
  end

  def self.find_or_create_by_tag_name(name)
    self.where("UPPER(name) = UPPER(?)", name).first_or_create!(:name => name)
  end

  private

  def reindex_tagged_objects
    taggings = Tagging.where(tag_id: id)
    objects_to_reindex = taggings.map(&:taggable).map do |obj|
      [obj.class.to_s, obj.id]
    end
    QC.enqueue_if_not_queued("SolrIndexer.reindex_objects", objects_to_reindex)
  end
end
