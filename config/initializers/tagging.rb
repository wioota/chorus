class ActsAsTaggableOn::Tagging
  belongs_to :tag, :counter_cache => true, :class_name => 'ActsAsTaggableOn::Tag'
end