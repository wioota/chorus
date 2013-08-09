chorus.views.JobSidebar = chorus.views.Sidebar.extend({
    constructorName: "JobSidebar",
    templateName:"job_sidebar",

    events: {
        "click .disable": "disableJob",
        "click .enable": "enableJob",
        'click .edit_job': 'launchEditDialog',
        'click .run_job': 'runJob',
        'click .delete_job': 'launchDeleteAlert'
    },

    disableJob: function(e) {
        e && e.preventDefault();
        this.model.disable();
    },

    enableJob: function(e) {
        e && e.preventDefault();
        this.model.enable();
    },

    additionalContext: function () {
        return this.model ? {
            enabled: this.model.get('enabled')
        } : {};
    },

    launchEditDialog: function (e) {
        e && e.preventDefault();
        new chorus.dialogs.EditJob({model: this.model}).launchModal();
    },

    launchDeleteAlert: function (e) {
        e && e.preventDefault();
        new chorus.alerts.JobDelete({model: this.model}).launchModal();
    },

    runJob: function (e) {
        e && e.preventDefault();
        this.model.run();
    }
});