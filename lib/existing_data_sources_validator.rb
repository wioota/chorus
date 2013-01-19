module ExistingDataSourcesValidator
  def self.run
    datasources = [GpdbInstance, OracleInstance, HadoopInstance, GnipInstance]
    invalid_instances = datasources.reduce([]) { |records, datasource|
      records << self.validate_instances_of(datasource)
    }.flatten

    if(invalid_instances.empty?)
      return true
    else
      log("Duplicate data source names found: #{invalid_instances.map(&:name).uniq.join(", ")}")
      return false
    end
  end

  def self.log(*args)
    puts *args
  end

  private

  def self.validate_instances_of(type)
    type.all.select do |record|
      DataSourceNameValidator.new(record).validate(record)
      record.errors.size > 0
    end
  end
end