chorus.models.DynamicDataset = function(attributes) {
    if(attributes && attributes.workspace) {
        if(attributes.entitySubtype === "CHORUS_VIEW") {
            return new chorus.models.ChorusView(attributes);
        } else if (attributes.entitySubtype === "HDFS") {
            return new chorus.models.HdfsDataset(attributes);
        } else {
            return new chorus.models.WorkspaceDataset(attributes);
        }
    } else {
        return new chorus.models.Dataset(attributes);
    }
};