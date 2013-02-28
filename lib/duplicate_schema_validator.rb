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
          link_datasets(original, duplicate)

          puts "Destroying Schema ##{duplicate.id}"
          ActiveRecord::Base.connection.execute(<<-SQL)
            DELETE
            FROM schemas
            WHERE id = #{duplicate.id}
          SQL
        end

        original
      end
    end

    true
  end

  private

  def self.get_duplicate_schemas
    if ActiveRecord::Base.connection.index_exists? :schemas, [:name, :parent_id, :parent_type], :unique => true
      return {}
    end

    schemas = Schema.all

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

  def self.link_datasets(original, duplicate)
    duplicate.datasets.each do |dup_dataset|
      original_dataset = original.datasets.find_or_create_by_name(dup_dataset.name)
      link_dataset_activities(original_dataset, dup_dataset)
      link_dataset_events(original_dataset, dup_dataset)
      link_dataset_associated_datasets(original_dataset, dup_dataset)
      link_dataset_import_schedules(original_dataset, dup_dataset)
      link_dataset_imports(original_dataset, dup_dataset)

      ActiveRecord::Base.connection.execute(<<-SQL)
        DELETE
        FROM datasets
        WHERE id = #{dup_dataset.id}
      SQL
    end
  end

  def self.link_dataset_activities(original, duplicate)
    Activity.where(:entity_id => duplicate.id,
                   :entity_type => POLYMORPHIC_DATASET_TYPES).each do |activity|
      activity.entity = original
      activity.save!
    end
  end

  def self.link_dataset_events(original, duplicate)
    query = Events::Base.where(
        :target1_id => duplicate.id,
        :target1_type => POLYMORPHIC_DATASET_TYPES
    )

    query.all.each do |event|
      event.target1 = original
      event.save!
    end

    query = Events::Base.where(
        :target2_id => duplicate.id,
        :target2_type => POLYMORPHIC_DATASET_TYPES
    )

    query.all.each do |event|
      event.target2 = original
      event.save!
    end
  end

  def self.link_dataset_associated_datasets(original, duplicate)
    AssociatedDataset.where(:dataset_id => duplicate.id).each do |association|
      association.dataset = original
      association.save!
    end
  end

  def self.link_dataset_import_schedules(original, duplicate)
    ImportSchedule.where(:source_dataset_id => duplicate.id).each do |schedule|
      schedule.source_dataset = original
      schedule.save!(:validate => false)
    end
  end

  def self.link_dataset_imports(original, duplicate)
    Import.where(:source_dataset_id => duplicate.id).each do |import|
      import.source_dataset = original
      import.save!(:validate => false)
    end
  end


  POLYMORPHIC_DATASET_TYPES = [
      'Dataset',
      'ChorusView',
      'GpdbTable',
      'OracleTable',
      'GpdbView',
      'OracleView'
  ]
end
