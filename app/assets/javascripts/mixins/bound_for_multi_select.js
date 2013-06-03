chorus.Mixins.BoundForMultiSelect = {
    preInitialize: function () {
        this.events["change .select_all"] = "changeSelection";
        this.subscribePageEvent("selectNone", this.anyUnselected);
        this.subscribePageEvent("unselectAny", this.anyUnselected);
        this.subscribePageEvent("selectAll", this.allSelected);
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

    allSelected: function () {
        this.$(".select_all").prop("checked", true);
    },

    anyUnselected: function () {
        this.$(".select_all").prop("checked", false);
    }
};