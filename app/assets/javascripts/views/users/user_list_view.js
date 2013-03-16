chorus.views.UserList = chorus.views.CheckableList.extend({
    eventName: "user",
    persistent: true,

    setup: function() {
        this.options.entityType = "user";
        this.options.entityViewType = chorus.views.User;
        this._super("setup", arguments);
    }
});
