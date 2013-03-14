class WorkspacePresenter < Presenter

  def to_hash
    results = {
        :id => model.id,
        :name => model.name,
        :is_deleted => model.deleted?,
        :entity_type => model.entity_type_name
    }
    unless rendering_activities?
      general_info = @options[:show_latest_comments] ? {} : {
          :summary => sanitize(model.summary),
          :owner => present(model.owner),
          :archiver => present(model.archiver),
          :archived_at => model.archived_at,
          :public => model.public,
          :image => present(model.image),
          :permission => model.permissions_for(current_user),
          :has_added_member => model.has_added_member,
          :has_added_workfile => model.has_added_workfile,
          :has_added_sandbox => model.has_added_sandbox,
          :has_changed_settings => model.has_changed_settings,
          :tags => present(model.tags, @options),
          :sandbox_info => present(model.sandbox)
      }
      results.merge!(general_info.merge(latest_comments_hash))
    end
    results
  end

  def complete_json?
    !rendering_activities?
  end

  private

  def latest_comments_hash
    return {} unless @options[:show_latest_comments]
    recent_notes = model.owned_notes.recent
    recent_comments = model.comments.recent

    recent_insights = recent_notes.where(:insight => true)

    recent_notes_and_comments = recent_notes.order("updated_at desc").limit(5) + recent_comments.order("updated_at desc").limit(5)

    latest_5 = recent_notes_and_comments.sort_by(&:updated_at).last(5)
    insight_count = latest_5.size == 0 ? 0 : recent_insights.size
    comment_count = latest_5.size == 0 ? 0 : recent_notes.size + recent_comments.size - insight_count

    {
        :number_of_insights => insight_count,
        :number_of_comments => comment_count,
        :latest_comment_list => present(latest_5)
    }
  end
end
