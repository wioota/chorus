chorus.views.DataTabDataset = chorus.views.Base.extend({
    constructorName: "DataTabDatasetView",
    templateName: "data_tab_dataset",
    tagName: "li",

    postRender: function() {
        this.$el.data("fullname", this.model.toText());
    },

    additionalContext: function() {
        return {
            name: this.model.name(),
            iconUrl: this.model.iconUrl({size: "small"})
        };
    }
});