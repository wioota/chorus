DROP DATABASE IF EXISTS "gpdb_test_database";
DROP DATABASE IF EXISTS "gpdb_test_database_priv";
DROP ROLE IF EXISTS "user_with_restricted_access";
DROP ROLE IF EXISTS "gpadmin";

CREATE ROLE "gpadmin" PASSWORD 'secret';
CREATE ROLE "user_with_restricted_access" PASSWORD 'secret';
CREATE DATABASE "gpdb_test_database" OWNER gpadmin;
REVOKE CONNECT ON DATABASE "gpdb_test_database" FROM PUBLIC;
CREATE DATABASE "gpdb_test_database_priv" OWNER gpadmin;