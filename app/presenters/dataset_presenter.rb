class DatasetPresenter < Presenter

  def to_hash
    notes = model.notes
    comments = model.comments

    recent_comments = [notes.last,
                       comments.last].compact
    recent_comments = *recent_comments.sort_by(&:created_at).last

    {
      :id => model.id,
      :entity_type => model.entity_type_name,
      :entity_subtype => thetype,
      :object_name => model.name,
      :schema => schema_hash,
      :recent_comments => present(recent_comments, :as_comment => true),
      :comment_count => comments.count + notes.count,
      :tags => present(model.tags),
      :is_deleted => !model.deleted_at.nil?
    }.merge(workspace_hash).
      merge(credentials_hash).
      merge(associated_workspaces_hash).
      merge(frequency).
      merge(tableau_workbooks_hash)
  end

  def complete_json?
    !rendering_activities?
  end

  private

  def schema_hash
    rendering_activities? ? {:id => model.schema_id } : present(model.schema)
  end

  def thetype
    if options[:workspace] && !model.source_dataset_for(options[:workspace])
      "SANDBOX_TABLE"
    else
      "SOURCE_TABLE"
    end
  end

  def workspace_hash
    options[:workspace] ? {:workspace => present(options[:workspace], @options)} : {}
  end

  def credentials_hash
    {
        :has_credentials => rendering_activities? ? false : model.accessible_to(current_user)
    }
  end

  def frequency
    if !rendering_activities? && options[:workspace] && options[:workspace].id
      import_schedule = model.import_schedules.where(:workspace_id => options[:workspace].id)
      {:frequency => import_schedule.first ? import_schedule.first.frequency : ""}
    else
      {:frequency => ""}
    end
  end

  def associated_workspaces_hash
    return {:associated_workspaces => []} if rendering_activities?
    workspaces = model.bound_workspaces.map do |workspace|
      {:id => workspace.id, :name => workspace.name}
    end

    {:associated_workspaces => workspaces}
  end

  def tableau_workbooks_hash
    return {} unless has_tableau_workbooks?
    return {:tableau_workbooks => []} if rendering_activities?
    tableau_workbooks = model.tableau_workbook_publications.map do |workbook|
      { :id => workbook.id,
        :name => workbook.name,
        :url => workbook.workbook_url
      }
    end

    { :tableau_workbooks => tableau_workbooks }
  end

  def has_tableau_workbooks?
    false
  end
end
