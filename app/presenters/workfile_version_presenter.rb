class WorkfileVersionPresenter < Presenter

  def to_hash
    present(model.workfile, options.merge(:include_execution_schema => true) ).merge({
      :version_info => {
        :id => model.id,
        :version_num => model.version_num,
        :commit_message => model.commit_message,
        :owner => owner_hash,
        :modifier => modifier_hash,
        :created_at => model.created_at,
        :updated_at => model.updated_at,
        :content_url => model.contents.url,
        :icon_url => icon_url,
        :content => content_value
      }
    })
  end

  def content_value
    options[:contents] ? model.get_content : nil
  end

  def owner_hash
    rendering_activities? ? { :id => model.owner_id } : present(model.owner, options.merge(:succinct => true))
  end

  def modifier_hash
    rendering_activities? ? { :id => model.modifier_id } : present(model.modifier, options.merge(:succinct => true))
  end

  def icon_url
    model.contents.url(:icon) if model.image?
  end

  def complete_json?
    !rendering_activities? && options[:contents]
  end
end
