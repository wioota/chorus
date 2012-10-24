class WorkfilePresenter < Presenter

  def to_hash
    workfile = {
      :id => model.id,
      :workspace => present(model.workspace, @options),
      :owner => present(model.owner),
      :file_name => h(model.file_name),
      :file_type => h(model.content_type),
      :latest_version_id => latest_workfile_version.id,
      :has_draft => model.has_draft(current_user),
      :is_deleted => model.deleted?
    }
    workfile[:execution_schema] = present(model.execution_schema) if options[:include_execution_schema]
    workfile
  end

  def complete_json?
    options[:include_execution_schema]
  end

  def latest_workfile_version
    model.latest_workfile_version
  end

end
