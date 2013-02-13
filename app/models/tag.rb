class Tag < ActiveRecord::Base
  has_many :taggables, :through => :taggings
  has_many :taggings

  attr_accessible :name
  attr_accessor :highlighted_attributes, :search_result_notes

  searchable do
    string :type_name
    text :name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
  end

  def self.named_like(name)
    where(["name ILIKE ?", "%#{name}%"])
  end

  def self.reset_counters
    # TODO
  end
end