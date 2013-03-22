chorus.views.SchemaList = chorus.views.CheckableList.extend({
    eventName: "schema",
    persistent: true,

    setup: function() {
        this.options.entityType = "schema";
        this.options.entityViewType = chorus.views.SchemaItem;
        this._super("setup", arguments);
    }
});
