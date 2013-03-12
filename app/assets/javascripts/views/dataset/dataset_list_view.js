chorus.views.DatasetList = chorus.views.CheckableList.extend({
    constructorName: "DatasetListView",
    useLoadingSection: true,
    eventName: "dataset",
    persistent: true,

    setup: function() {
        this.options.entityType = "dataset";
        this.options.entityViewType = chorus.views.Dataset;
        this.options.listItemOptions = {
            activeWorkspace: this.options.activeWorkspace,
            checkable: this.options.checkable
        };

        this._super("setup", arguments);
    },

    postRender: function() {
        var $list = $(this.el);
        if(this.collection.length === 0 && this.collection.loaded) {
            var linkText = Handlebars.helpers.linkTo("#/data_sources", t("datasource.browse"));
            var noDatasetEl = $("<div class='browse_more'></div>");

            var hintText;
            if (this.collection.hasFilter && this.collection.hasFilter()) {
                hintText = t("dataset.filtered_empty");
            } else if (this.collection.attributes.workspaceId) {
                hintText = t("dataset.browse_more_workspace", {linkText: linkText});
            } else {
                hintText = t("dataset.browse_more_instance", {linkText: linkText});
            }

            noDatasetEl.append(hintText);
            $list.append(noDatasetEl);
        }

        this._super("postRender", arguments);
    }
});
