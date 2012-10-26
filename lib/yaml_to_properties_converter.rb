module YamlToPropertiesConverter
  def self.write_properties(hash, parents='')
    hash.map {|key, value|
      if value.is_a?(Hash)
        self.write_properties(value, parents + "#{key}.")
      else
        ["#{parents}#{key}= #{value}"]
      end
    }.flatten
  end

  def self.convert_yml_to_properties(source_path, destination_path)
    hash = YAML.load_file(source_path)
    list = self.write_properties(hash)
    File.open(destination_path, 'w') do |f|
      list.each { |property| f.print(property, "\n") }
    end
  end
end