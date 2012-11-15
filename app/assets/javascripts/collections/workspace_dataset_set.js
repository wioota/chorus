chorus.collections.WorkspaceDatasetSet = chorus.collections.LastFetchWins.extend({

    model: chorus.models.DynamicDataset,
    constructorName: "WorkspaceDatasetSet",

    setup: function() {
        if(this.attributes.unsorted) {
            this.comparator = undefined;
        }
    },

    showUrlTemplate: "workspaces/{{workspaceId}}/datasets",
    urlTemplate: "workspaces/{{workspaceId}}/datasets",

    save: function() {
        var ids = _.pluck(this.models, 'id');
        new chorus.models.BulkSaver({collection: this}).save({datasetIds: ids});
    },

    urlParams: function(options) {
        return {
            namePattern: this.attributes.namePattern,
            databaseName: this.attributes.databaseName,
            type: this.attributes.type
        };
    },

    comparator: function(dataset) {
        return dataset.get("objectName").toLowerCase();
    },

    search: function(term) {
        var self = this;
        self.attributes.namePattern = term;
        self.fetch({silent: true, success: function() { self.trigger('searched'); }});
    },

    hasFilter: function() {
        return !this.attributes.namePattern == "" || !this.attributes.type == "";
    }
});
