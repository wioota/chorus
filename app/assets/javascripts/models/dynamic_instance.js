chorus.models.DynamicInstance = function(dataSourceJSON) {
    var typeMap = {
        instance: 'GpdbDataSource',
        gpdb_data_source: 'GpdbDataSource',
        hdfs_data_source: 'HdfsDataSource',
        gnip_data_source: 'GnipDataSource',
        oracle_data_source: 'OracleDataSource'
    };

    if (!chorus.models[typeMap[dataSourceJSON.entityType]]) {
        window.console.error("Unknown Data Source Type!", dataSourceJSON.entityType, dataSourceJSON);
    }

    return new chorus.models[typeMap[dataSourceJSON.entityType]](dataSourceJSON);
};
