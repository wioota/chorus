module Sequel
  module JDBC
    DATABASE_SETUP[:teradata] = proc do |db|
      com.teradata.jdbc.TeraDriver
    end
    DATABASE_SETUP[:vertica] = proc do |db|
      com.vertica.jdbc.Driver
    end
    DATABASE_SETUP[:mariadb] = proc do |db|
      org.mariadb.jdbc.Driver
    end
  end
end
