module ImportConsole
  module ImportsHelper
    def table_description(schema, table_name)
      description = ''
      if schema.respond_to?(:database) && !schema.database.nil?
        description << schema.database.name + "."
      end
      description << schema.name + "." + table_name
    end

    def instance_description_for_schema(schema)
      if schema
        instance = schema.data_source
        if instance
          instance.host + ":" + instance.port.to_s
        else
          "#{schema.name} has no instance"
        end
      else
        "No schema found."
      end
    end

    def link_to_table(workspace_or_schema, dataset)
      if workspace_or_schema.is_a? Schema
        "/#/datasets/#{dataset.id}"
      else
        type = dataset.type == "ChorusView" ? "chorus_views" : "datasets"
        "/#/workspaces/#{workspace_or_schema.id}/#{type}/#{dataset.id}"
      end
    end

    def link_to_destination(import_manager)
      to_table = import_manager.to_table
      schema_or_sandbox = import_manager.schema_or_sandbox
      description = table_description(schema_or_sandbox, to_table)
      dest_table = schema_or_sandbox.datasets.find_by_name(to_table)
      if dest_table
        link_to(description, link_to_table(import_manager.schema_or_workspace_with_deleted, dest_table))
      else
        description
      end
    end

    def show_process
      yield || "Not found"
    rescue Exception => e
      "#{e}: #{e.message} - #{e.backtrace}"
    end
  end
end