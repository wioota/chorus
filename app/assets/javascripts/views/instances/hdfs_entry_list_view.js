chorus.views.HdfsEntryList = chorus.views.CheckableList.extend({
    constructorName: "HdfsEntryList",
    useLoadingSection: true,
    eventName: "hdfs_entry",

    setup: function() {
        this.options.entityType = "hdfs_entry";
        this.options.entityViewType = chorus.views.HdfsEntry;
        this._super("setup", arguments);
    },

    selectAll: function() {
        var files = _.reject(this.collection.models, function(entry) {
            return entry.get('isDir');
        });

        this.selectedModels.reset(files);
        chorus.PageEvents.broadcast("checked", this.selectedModels);
        chorus.PageEvents.broadcast(this.eventName + ":checked", this.selectedModels);
    }
});
