chorus.models.DynamicWorkfile = function(modelJson) {
    var typeMap = {
        alpine: 'AlpineWorkfile'
    };

    if (!chorus.models[typeMap[modelJson.type]]) {
        return new chorus.models.Workfile(modelJson);
    }

    return new chorus.models[typeMap[modelJson.type]](modelJson);
};
