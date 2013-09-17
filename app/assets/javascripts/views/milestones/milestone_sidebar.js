chorus.views.MilestoneSidebar = chorus.views.Sidebar.extend({
    constructorName: "MilestoneSidebar",
    templateName: "milestone_sidebar",

    subviews:{
        '.tab_control': 'tabs'
    },

    events: {
        'click a.edit_milestone': 'launchEditDialog'
    },

    setup: function() {
    },

    additionalContext: function () {
        return this.model ? {

        } : {};
    },

    launchEditDialog: function (e) {
    }
});