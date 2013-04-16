//= require views/layout/page_item_list_view

chorus.views.HdfsEntryList = chorus.views.PageItemList.extend({
    eventName: "hdfs_entry",
    constructorName: "HdfsEntryList",
    useLoadingSection: true,

    setup: function() {
        this.options.entityType = "hdfs_entry";
        this.options.entityViewType = chorus.views.HdfsEntryItem;
        this._super("setup", arguments);
    },

    selectAll: function() {
        var files = this.collection.reject(function(entry) {
            return entry.get('isDir');
        });

        this.selectedModels.reset(files);
        chorus.PageEvents.trigger("checked", this.selectedModels);
        chorus.PageEvents.trigger(this.eventName + ":checked", this.selectedModels);
    }
});
