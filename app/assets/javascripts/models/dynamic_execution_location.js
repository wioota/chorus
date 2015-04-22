chorus.models.DynamicExecutionLocation = function(attributes) {
    if (attributes) {
        if(attributes.entityType === "hdfs_data_source") {
            return new chorus.models.HdfsDataSource(attributes);
        } else if(attributes.entityType === "oracle_data_source") {
            return new chorus.models.OracleDataSource(attributes);
        } else if(attributes.entityType === "jdbc_data_source") {
            return new chorus.models.JdbcDataSource(attributes);
        } else if(attributes.entityType === "jdbc_hive_data_source") {
            return new chorus.models.JdbcHiveDataSource(attributes);
        }
    }
    return new chorus.models.Database(attributes);
};
