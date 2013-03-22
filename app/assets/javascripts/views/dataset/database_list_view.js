chorus.views.DatabaseList = chorus.views.CheckableList.extend({
    constructorName: 'DatabaseListView',
    useLoadingSection: true,
    eventName: "database",

    setup: function() {
        this.options.entityType = "database";
        this.options.entityViewType = chorus.views.DatabaseItem;
        this._super("setup", arguments);
    }
});
