module ImportConsole::ImportsHelper
  def table_description(schema, table_name)
    schema.database.name + "." + schema.name + "." + table_name
  end

  def instance_description_for_schema(schema)
    if schema
      instance = schema.gpdb_instance
      if instance
        instance.host + ":" + instance.port.to_s
      else
        "#{schema.name} has no instance"
      end
    else
      "No schema found."
    end
  end

  def link_to_table(workspace, dataset)
    type = dataset.type == "CHORUS_VIEW" ? "chorus_views" : "dataset"
    "/#/workspace/#{workspace.id}/#{type}/#{dataset.id}"
  end

  def link_to_destination(workspace, to_table)
    description = table_description(workspace.sandbox, to_table)
    dest_table = workspace.sandbox.datasets.find_by_name(to_table)
    if dest_table
      link_to(description, link_to_table(workspace, dest_table))
    else
      description
    end
  end

  def show_process
    yield || "Not found"
  rescue Exception => e
    "#{e}"
  end
end
