module TaggableBehavior
  extend ActiveSupport::Concern

  included do
    has_many :taggings, :as => :taggable
    has_many :tags, :through => :taggings
  end

  module ClassMethods
    def taggable?
      true
    end
  end

  def tag_list=(tags_list)
    tags_list.split(",").each do |tag|
      found_tag = Tag.find_or_create_by_name(tag)
      self.tags << found_tag unless self.tags.include?(found_tag)
    end
  end
end