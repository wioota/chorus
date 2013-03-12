chorus.models.DynamicInstance = function(instanceJson) {
    var typeMap = {
        instance: 'GpdbDataSource',
        gpdb_data_source: 'GpdbDataSource',
        hdfs_data_source: 'HdfsDataSource',
        gnip_data_source: 'GnipDataSource',
        oracle_data_source: 'OracleDataSource'
    };

    if (!chorus.models[typeMap[instanceJson.entityType]]) {
        window.console.error("constructing dynamic instance", instanceJson.entityType, instanceJson);
    }

    return new chorus.models[typeMap[instanceJson.entityType]](instanceJson);
};
