class WorkfilePresenter < Presenter

  def to_hash
    notes = model.notes
    comments = model.comments
    commit_messages = model.commit_messages

    # optimized so the happy path only does one LIMIT 1 sql query
    while commit_messages.last && !latest_commit_message?(commit_messages.last)
      commit_messages.pop
    end

    recent_comments = [notes.last,
                       comments.last,
                       commit_messages.last].compact
    recent_comments = *recent_comments.sort_by(&:created_at).last

    workfile = {
      :id => model.id,
      :workspace => present(model.workspace, @options),
      :file_name => model.file_name,
      :file_type => model.content_type,
      :latest_version_id => model.latest_workfile_version_id,
      :is_deleted => model.deleted?,
      :recent_comments => present(recent_comments, :as_comment => true),
      :comment_count => comments.count + notes.count
    }

    unless rendering_activities?
      workfile.merge!({
        :owner => present(model.owner),
        :has_draft => model.has_draft(current_user)
      })
    end
    workfile[:execution_schema] = present(model.execution_schema) if options[:include_execution_schema]
    workfile
  end

  def latest_commit_message?(message)
    !message.is_a?(Events::WorkfileUpgradedVersion) ||
        message.version_id == model.latest_workfile_version_id
  end

  def complete_json?
    options[:include_execution_schema] && !rendering_activities?
  end
end
