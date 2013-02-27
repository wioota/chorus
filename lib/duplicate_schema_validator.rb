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

  def self.get_duplicate_schemas
    schemas = Schema.all

    indexed_schemas = schemas.inject({}) do |indexed, schema|
      key = [schema.name, schema.parent_id, schema.parent_type].to_param
      indexed[key] ||= []
      indexed[key] << schema
      indexed
    end

    indexed_schemas.select {|k, v| v.size > 1}
  end
end
