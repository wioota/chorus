DROP DATABASE IF EXISTS "gpdb_test_database";
DROP DATABASE IF EXISTS "gpdb_test_database_priv";
DROP DATABASE IF EXISTS "gpdb_test_database_with_''_";
DROP ROLE IF EXISTS "user_with_restricted_access";
-- DROP DATABASE IF EXISTS "gpdb_test_database_with_""_";

CREATE ROLE "user_with_restricted_access" PASSWORD 'secret';
CREATE DATABASE "gpdb_test_database" OWNER gpadmin;
REVOKE CONNECT ON DATABASE "gpdb_test_database" FROM PUBLIC;
CREATE DATABASE "gpdb_test_database_priv" OWNER gpadmin;
CREATE DATABASE "gpdb_test_database_with_''_" OWNER gpadmin;
-- CREATE DATABASE "gpdb_test_database_with_""_" OWNER gpadmin;
