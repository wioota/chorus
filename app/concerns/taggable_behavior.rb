module TaggableBehavior
  extend ActiveSupport::Concern

  included do
    has_many :taggings, :as => :taggable, :dependent => :destroy
    has_many :tags, :through => :taggings
  end

  module ClassMethods
    def taggable?
      true
    end
  end

  def tag_list=(tags_list)
    self.tags = tags_list.map do |tag_name|
      begin
        Tag.create!(name: tag_name)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e # find_or_create_by_name is not concurrent-safe
        Tag.first(:conditions => [ "lower(name) = ?", tag_name.downcase ])
      end
    end
  end
end