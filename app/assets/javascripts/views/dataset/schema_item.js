chorus.views.SchemaItem = chorus.views.Base.extend(chorus.Mixins.TagsContext).extend({
    templateName: "schema_item",
    tagName: "li",

    additionalContext: function() {
        return {
            showUrl: this.model.showUrl(),
            datasetMessage: (function(model) {
                var datasetCount = model.get('datasetCount');
                return model.get('refreshedAt') ? I18n.t("entity.name.WorkspaceDataset", {count: datasetCount}) : I18n.t("entity.name.WorkspaceDataset.refreshing");
            })(this.model)
        };
    }
});
