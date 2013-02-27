module DuplicateSchemaValidator
  def self.run
    duplicate_schemas = get_duplicate_schemas

    if duplicate_schemas.empty?
      true
    else
      dup_names = duplicate_schemas.map {|k, schemas| schemas.first.name }
      puts "Duplicate schemas found: #{dup_names}"
      false
    end
  end

  def self.run_and_fix
    get_duplicate_schemas.values.each do |schema_list|
      schema_list.inject(schema_list.first) do |original, duplicate|
        if original != duplicate
          link_workfiles(original, duplicate)
          link_workspaces(original, duplicate)
          link_chorus_views(original, duplicate)
          duplicate.destroy
        end

        original
      end
    end

    true
  end

  private

  def self.get_duplicate_schemas
    schemas = Schema.where(:deleted_at => nil).all

    indexed_schemas = schemas.inject({}) do |indexed, schema|
      key = [schema.name, schema.parent_id, schema.parent_type].to_param
      indexed[key] ||= []
      indexed[key] << schema
      indexed
    end

    indexed_schemas.select {|k, v| v.size > 1}
  end

  def self.link_workfiles(original, duplicate)
    Workfile.where(:execution_schema_id => duplicate.id).each do |workfile|
      workfile.execution_schema = original
      workfile.save!
    end
  end

  def self.link_workspaces(original, duplicate)
    Workspace.where(:sandbox_id => duplicate.id).each do |workspace|
      workspace.sandbox = original
      workspace.save!
    end
  end
  
  def self.link_chorus_views(original, duplicate)
    ChorusView.where(:schema_id => duplicate.id).each do |view|
      ActiveRecord::Base.connection.execute(<<-SQL)
        UPDATE datasets
        SET schema_id=#{original.id}
        WHERE id=#{view.id}
      SQL
    end
  end
end
