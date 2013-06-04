chorus.Mixins.BoundForMultiSelect = {
    preInitialize: function () {
        this.events["change .select_all"] = "changeSelection";
        this.subscribePageEvent("selectNone", this.anyUnselected);
        this.subscribePageEvent("unselectAny", this.anyUnselected);
        this.subscribePageEvent("allSelected", this.allSelected);
        this.selectAllChecked = false;
        this._super("preInitialize", arguments);
    },

    changeSelection: function(e) {
        e.preventDefault();
        if ($(e.currentTarget).is(":checked")) {
            chorus.PageEvents.trigger("selectAll");
            this.selectAllChecked = true;
        } else {
            chorus.PageEvents.trigger("selectNone");
            this.selectAllChecked = false;
        }
    },

    renderCheckedState: function () {
        this.$(".select_all").prop("checked", this.selectAllChecked);
    },

    allSelected: function () {
        this.$(".select_all").prop("checked", true);
        this.selectAllChecked = true;
    },

    anyUnselected: function () {
        this.$(".select_all").prop("checked", false);
        this.selectAllChecked = false;
    }
};