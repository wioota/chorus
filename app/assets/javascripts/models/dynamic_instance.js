chorus.models.DynamicInstance = function(instanceJson) {
    var typeMap = {
        instance: 'GpdbInstance',
        gpdb_instance: 'GpdbInstance',
        hadoop_instance: 'HadoopInstance',
        gnip_instance: 'GnipInstance'
    };

    if (!chorus.models[typeMap[instanceJson.entityType]]) {
        console.error("constructing dynamic instance", instanceJson.entityType, instanceJson)
    }

    return new chorus.models[typeMap[instanceJson.entityType]](instanceJson);
};
