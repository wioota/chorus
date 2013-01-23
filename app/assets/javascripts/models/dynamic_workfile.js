chorus.models.DynamicWorkfile = function(modelJson) {
    var typeMap = chorus.models.DynamicWorkfile.typeMap;

    if (!chorus.models[typeMap[modelJson.type]]) {
        return new chorus.models.Workfile(modelJson);
    }

    return new chorus.models[typeMap[modelJson.type]](modelJson);
};

chorus.models.DynamicWorkfile.typeMap = {
    alpine: 'AlpineWorkfile'
};