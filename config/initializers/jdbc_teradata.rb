if File.exist?(Rails.root.join('lib', 'libraries' , 'terajdbc4.jar')) && File.exist?(Rails.root.join('lib', 'libraries' , 'tdgssconfig.jar'))

  require 'sequel/adapters/jdbc'
  require Rails.root.join('lib', 'libraries' , 'terajdbc4.jar')
  require Rails.root.join('lib', 'libraries' , 'tdgssconfig.jar')

  module Sequel
    module JDBC
      DATABASE_SETUP[:teradata] = proc do |db|
        com.teradata.jdbc.TeraDriver
      end
    end
  end

end

