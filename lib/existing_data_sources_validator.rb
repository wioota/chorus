module ExistingDataSourcesValidator
  def self.log(*args)
    puts *args
  end

  def self.run(data_source_types)
    log "Searching for duplicate data source names..."

    existing_data_source_types = data_source_types.select { |data_source|
      ActiveRecord::Base.connection.table_exists? data_source.table_name
    }

    invalid_instances = find_invalid_instances(existing_data_source_types)

    if invalid_instances.empty?
      return true
    else
      log "Duplicate data source names found: #{invalid_instances.uniq.join(", ")}"
      return false
    end
  end

  private

  def self.find_invalid_instances(data_source_types)
    names = []
    data_source_types.each do |type|
      names += ActiveRecord::Base.connection.exec_query("select * from #{type.table_name}").map {|record| record["name"] }
    end

    names.reject { |name| names.count(name) == 1 }
  end
end