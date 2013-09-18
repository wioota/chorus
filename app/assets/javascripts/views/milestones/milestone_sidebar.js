chorus.views.MilestoneSidebar = chorus.views.Sidebar.extend({
    constructorName: "MilestoneSidebar",
    templateName: "milestone_sidebar",

    subviews:{
        '.tab_control': 'tabs'
    },

    events: {
        'click a.delete_milestone': 'launchDeleteAlert'
    },

    setup: function() {
    },

    additionalContext: function () {
        return this.model ? {

        } : {};
    },

    launchDeleteAlert: function (e) {
        e && e.preventDefault();
        new chorus.alerts.MilestoneDelete({model: this.model}).launchModal();
    },

    launchEditDialog: function (e) {
    }
});