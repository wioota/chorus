chorus.models.DynamicExecutionLocation = function(attributes) {
    if(attributes && attributes.entityType === "hdfs_data_source") {
        return new chorus.models.HdfsDataSource(attributes);
    } else {
        return new chorus.models.Database(attributes);
    }
};