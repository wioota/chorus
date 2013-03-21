chorus.views.UserList = chorus.views.CheckableList.extend({
    eventName: "user",

    setup: function() {
        this.options.entityType = "user";
        this.options.entityViewType = chorus.views.User;
        this._super("setup", arguments);
    }
});
