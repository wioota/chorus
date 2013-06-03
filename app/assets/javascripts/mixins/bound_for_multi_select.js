chorus.Mixins.BoundForMultiSelect = {
    preInitialize: function () {
        this.events["change .select_all"] = "changeSelection";
        this.subscribePageEvent("selectNone", this.noneSelected);
        this._super("preInitialize", arguments);
    },

    changeSelection: function(e) {
        e.preventDefault();
        if ($(e.currentTarget).is(":checked")) {
            chorus.PageEvents.trigger("selectAll");
        } else {
            chorus.PageEvents.trigger("selectNone");
        }
    },

    noneSelected: function () {
        this.$(".select_all").prop("checked", false);
    }
};