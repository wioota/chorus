module Validator
  def self.valid?
    invalid_instances = GpdbInstance.all.select{ |instance| !instance.valid? }
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
end