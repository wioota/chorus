class WorkfilePresenter < Presenter

  def to_hash
    notes = model.notes
    comments = model.comments

    recent_comments = [notes.last,
                       comments.last].compact
    recent_comments = *recent_comments.sort_by(&:created_at).last

    workfile = {
      :id => model.id,
      :type => model.entity_type,
      :workspace => present(model.workspace, @options),
      :file_name => model.file_name,
      :file_type => model.content_type,
      :latest_version_id => model.latest_workfile_version_id,
      :is_deleted => model.deleted?,
      :recent_comments => present(recent_comments, :as_comment => true),
      :comment_count => comments.count + notes.count,
      :tags => present(model.tags, @options)
    }

    unless rendering_activities?
      workfile.merge!({
        :owner => present(model.owner),
      })
    end
    workfile.merge!(model.additional_data)
    workfile
  end

  def complete_json?
    !rendering_activities?
  end
end
