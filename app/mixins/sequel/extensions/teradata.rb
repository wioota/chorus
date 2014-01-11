module Sequel
  module JDBC
    DATABASE_SETUP[:teradata] = proc do |db|
      com.teradata.jdbc.TeraDriver
    end
  end
end