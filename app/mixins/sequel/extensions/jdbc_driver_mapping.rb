module Sequel
  module JDBC
    DATABASE_SETUP[:teradata] = proc do |db|
      com.teradata.jdbc.TeraDriver
    end
    DATABASE_SETUP[:vertica] = proc do |db|
      com.vertica.jdbc.Driver
    end
  end
end