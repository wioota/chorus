chorus.views.UserList = chorus.views.CheckableList.extend({
    constructorName: "UserListView",
    eventName: "user",

    setup: function() {
        this.options.entityType = "user";
        this.options.entityViewType = chorus.views.UserItem;
        this._super("setup", arguments);
    }
});
