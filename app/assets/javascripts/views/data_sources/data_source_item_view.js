chorus.views.DataSourceItem = chorus.views.Base.extend({
    constructorName: "DataSourceItemView",
    templateName: "data_source_item",

    additionalContext: function() {
        return {
            stateUrl: this.model.stateIconUrl(),
            url: this.model.showUrl(),
            providerUrl: this.model.providerIconUrl(),
            stateText: this.model.stateText(),
            tags: this.model.tags().models
        };
    }
});