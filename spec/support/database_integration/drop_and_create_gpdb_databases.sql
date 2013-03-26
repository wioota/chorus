DROP DATABASE IF EXISTS "gpdb_test_database";
DROP DATABASE IF EXISTS "gpdb_test_database_priv";
DROP DATABASE IF EXISTS "gpdb_test_database_with_''_";
DROP DATABASE IF EXISTS "gpdb_test_database_wo_pub";
-- DROP DATABASE IF EXISTS "gpdb_test_database_with_""_";

CREATE DATABASE "gpdb_test_database" OWNER gpadmin;
REVOKE CONNECT ON DATABASE "gpdb_test_database" FROM PUBLIC;
CREATE DATABASE "gpdb_test_database_priv" OWNER gpadmin;
CREATE DATABASE "gpdb_test_database_with_''_" OWNER gpadmin;
CREATE DATABASE "gpdb_test_database_wo_pub" OWNER gpadmin;
-- CREATE DATABASE "gpdb_test_database_with_""_" OWNER gpadmin;