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
    self.tags = tags_list.map { |tag| Tag.find_or_create_by_tag_name(tag) }
  end
end