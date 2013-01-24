chorus.models.DynamicInstance = function(instanceJson) {
    var typeMap = {
        instance: 'GpdbDataSource',
        gpdb_data_source: 'GpdbDataSource',
        hadoop_instance: 'HadoopInstance',
        gnip_instance: 'GnipInstance'
    };

    if (!chorus.models[typeMap[instanceJson.entityType]]) {
        window.console.error("constructing dynamic instance", instanceJson.entityType, instanceJson);
    }

    return new chorus.models[typeMap[instanceJson.entityType]](instanceJson);
};
