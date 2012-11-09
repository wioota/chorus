class WorkfilePresenter < Presenter

  def to_hash
    comments_and_notes = model.notes + model.comments_on_notes
    comments_and_notes.sort_by!(&:created_at).reverse!

    workfile = {
      :id => model.id,
      :workspace => present(model.workspace, @options),
      :file_name => model.file_name,
      :file_type => model.content_type,
      :latest_version_id => model.latest_workfile_version_id,
      :is_deleted => model.deleted?,
      :recent_comments => comments_and_notes.map do |comment|
        {
            :body => comment.body,
            :author => present(comment.author),
            :timestamp => comment.created_at
        }
      end,
      :comment_count => comments_and_notes.count
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
