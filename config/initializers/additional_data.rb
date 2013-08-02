require 'json'

class ActiveRecord::Base
  def self.has_additional_data(*name_datas)
    column_names = name_datas.map do |name_data|
      name, _ = name_data
      name
    end
    attr_accessible(*column_names, :as => [:default, :create])
    name_datas.each do |name_data|
      name, type = name_data
      define_method(name) do
        additional_data[name.to_s]
      end
      define_method("#{name}=") do |value|
        if type && type == :boolean
          value = false if value == "false"
          value = true if value == "true"
          raise ArgumentError.new("invalid value for Boolean: \"#{self}\"") unless [true, false].include?(value)
        end
        additional_data[name.to_s] = value
      end
    end
  end
end