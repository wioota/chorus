module ExistingDataSourcesValidator
  def self.run(data_source_types)
    puts "Searching for duplicate data source names..."

    existing_data_source_types = data_source_types.select { |data_source|
      ActiveRecord::Base.connection.table_exists? data_source.table_name
    }

    invalid_instances = find_invalid_instances(existing_data_source_types)

    if invalid_instances.empty?
      return true
    else
      puts "Duplicate data source names found: #{invalid_instances.map(&:name).uniq.join(", ")}"
      return false
    end
  end

  private

  def self.find_invalid_instances(data_source_types)
    invalid_instances = []

    data_source_types.each do |type|
      type.all.each do |record|
        data_source_types.each do |other_type|
          other_type.where('LOWER(name) = ?', record.name.downcase).each do |invalid_instance|
            next if invalid_instance == record
            invalid_instances << invalid_instance
          end
        end
      end
    end

    invalid_instances
  end
end