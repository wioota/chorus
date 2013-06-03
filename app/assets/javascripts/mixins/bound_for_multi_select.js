chorus.Mixins.BoundForMultiSelect = {
    preInitialize: function () {
        this.events["change .select_all"] = "changeSelection";
        this._super("preInitialize", arguments);
    },

    changeSelection: function(e) {
        e.preventDefault();
        if ($(e.currentTarget).is(":checked")) {
            chorus.PageEvents.trigger("selectAll");
        } else {
            chorus.PageEvents.trigger("selectNone");
        }
    }
};