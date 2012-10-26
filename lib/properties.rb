module Properties
  def self.load_file(file_path)
    result = {}
    compacted_lines(file_path).each do |line|
      match = line.match(/\s*(?<key>[^=\s]*)\s*=\s*(?<value>.*)/)
      if !match
        next
       end
      keys = match["key"].split(".")
      val = type_cast(match["value"])

      parent = result
      keys.first(keys.length-1).each do |key|
        parent = parent[key] || parent[key] = {}
      end
      parent[keys.last] = val
    end
    result
  end

  private
  def self.compacted_lines(file_path)
    propertiesString = File.read(file_path)
    lineJoiningRegex = /\\\s*\n/
    joinedLines = propertiesString.gsub(lineJoiningRegex, '').split("\n")
    joinedLines.reject {|line| line.match(/^\s*#/) }
  end

  def self.type_cast(value)
    case value
      when 'true'
        true
      when 'false'
        false
      when /^-?\d+$/
        value.to_i
      when /^-?\d+\.?\d*$/
        value.to_f
      else
        value
    end
  end
end