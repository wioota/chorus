module ActiveRecord
  class Base
    def self.from_param(param)
      find(param)
    end
  end
end
