chorus.views.SchemaList = chorus.views.SelectableList.extend({
    templateName: "schema_list",
    eventName: "schema",

    collectionModelContext: function(model) {
        return {
            showUrl: model.showUrl(),
            datasetMessage: this.datasetMessage(model)
        };
    },

    datasetMessage: function(model) {
        var datasetCount = model.get('datasetCount');

        if(model.get('refreshedAt') != null) {
            return I18n.t("entity.name.WorkspaceDataset", {count: datasetCount});
        } else {
            return I18n.t("entity.name.WorkspaceDataset.refreshing");
        }
    }
});
