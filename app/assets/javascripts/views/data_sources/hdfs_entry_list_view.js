chorus.views.HdfsEntryList = chorus.views.CheckableList.extend({
    eventName: "hdfs_entry",
    constructorName: "HdfsEntryList",
    useLoadingSection: true,

    setup: function() {
        this.options.entityType = "hdfs_entry";
        this.options.entityViewType = chorus.views.HdfsEntry;
        this._super("setup", arguments);
    },

    selectAll: function() {
        var files = this.collection.reject(function(entry) {
            return entry.get('isDir');
        });

        this.selectedModels.reset(files);
        chorus.PageEvents.broadcast("checked", this.selectedModels);
        chorus.PageEvents.broadcast(this.eventName + ":checked", this.selectedModels);
    }
});
