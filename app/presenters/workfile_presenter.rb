class WorkfilePresenter < Presenter

  def to_hash
    notes = model.events.select { |e| e.is_a?(Events::NoteOnWorkfile) }

    workfile = {
      :id => model.id,
      :workspace => present(model.workspace, @options),
      :file_name => model.file_name,
      :file_type => model.content_type,
      :latest_version_id => model.latest_workfile_version_id,
      :is_deleted => model.deleted?,
      :recent_comments => notes.map do |note|
        {
            :body => note.body,
            :author => present(note.actor),
            :timestamp => note.created_at
        }
      end,
      :comment_count => notes.count
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

  def complete_json?
    options[:include_execution_schema] && !rendering_activities?
  end
end
