chorus.models.DynamicDataset = function(attributes) {
    if(attributes && attributes.workspace) {
        if(attributes.entity_subtype === "CHORUS_VIEW") {
            return new chorus.models.ChorusView(attributes);
        } else {
            return new chorus.models.WorkspaceDataset(attributes);
        }
    } else {
        return new chorus.models.Dataset(attributes);
    }
};