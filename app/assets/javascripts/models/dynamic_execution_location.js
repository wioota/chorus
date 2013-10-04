chorus.models.DynamicExecutionLocation = function(attributes) {
    if (attributes) {
        if(attributes.entityType === "hdfs_data_source") {
            return new chorus.models.HdfsDataSource(attributes);
        } else if(attributes.entityType === "oracle_data_source") {
            return new chorus.models.OracleDataSource(attributes);
        }
    }
    return new chorus.models.Database(attributes);
};