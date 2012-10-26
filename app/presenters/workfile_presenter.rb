class WorkfilePresenter < Presenter

  def to_hash
    workfile = {
      :id => model.id,
      :workspace => present(model.workspace, @options),
      :file_name => h(model.file_name),
      :file_type => h(model.content_type),
      :latest_version_id => model.latest_workfile_version_id,
      :is_deleted => model.deleted?
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
