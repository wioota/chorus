class DatasetPresenter < Presenter

  def to_hash
    recent_comments = Array.wrap(recent_comment)
    {
        :id => model.id,
        :entity_type => model.entity_type_name,
        :entity_subtype => thetype,
        :object_name => model.name,
        :schema => schema_hash,
        :recent_comments => present(recent_comments, :as_comment => true),
        :comment_count => recent_comments.empty? ? 0 : model.comments.count + model.notes.count,
        :is_deleted => model.deleted?
    }.merge(workspace_hash).
        merge(credentials_hash).
        merge(associated_workspaces_hash).
        merge(frequency).
        merge(tableau_workbooks_hash).
        merge(tags_hash)
  end

  def complete_json?
    !rendering_activities?
  end

  private

  def recent_comment
    [model.most_recent_notes.last, model.most_recent_comments.last].compact.sort_by(&:created_at).last
  end

  def tags_hash
    rendering_activities? ? {} : {:tags => present(model.tags)}
  end

  def schema_hash
    rendering_activities? ? {:id => model.schema_id, :name => model.schema.name} : present(model.schema, options.merge(:succinct => true))
  end

  def thetype
    if sandbox_table?
      "SANDBOX_TABLE"
    else
      "SOURCE_TABLE"
    end
  end

  def sandbox_table?
    options[:workspace] && !model.source_dataset_for(options[:workspace])
  end

  def workspace_hash
    options[:workspace] ? {:workspace => present(options[:workspace], @options)} : {}
  end

  def credentials_hash
    if rendering_activities? || (sandbox_table? && !model.is_a?(ChorusView))
      {:has_credentials => true}
    else
      {:has_credentials => model.accessible_to(current_user)}
    end
  end

  def frequency
    if !rendering_activities? && options[:workspace] && options[:workspace].id
      import_schedule = model.import_schedules.to_a.select { |sched| sched.workspace_id == options[:workspace].id }.first
      {:frequency => import_schedule ? import_schedule.frequency : ""}
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
      {:id => workbook.id,
       :name => workbook.name,
       :url => workbook.workbook_url
      }
    end

    {:tableau_workbooks => tableau_workbooks}
  end

  def has_tableau_workbooks?
    false
  end
end
