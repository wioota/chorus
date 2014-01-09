if File.exist?(Rails.root.join('lib', 'libraries' , 'terajdbc4.jar')) &&
    File.exist?(Rails.root.join('lib', 'libraries' , 'tdgssconfig.jar'))

  require 'sequel/adapters/jdbc'

  module Sequel
    module JDBC
      DATABASE_SETUP[:teradata] = proc do |db|
        com.teradata.jdbc.TeraDriver
      end
    end
  end

end

