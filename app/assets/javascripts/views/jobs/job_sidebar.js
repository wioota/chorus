chorus.views.JobSidebar = chorus.views.Sidebar.extend({
    constructorName: "JobSidebar",
    templateName:"job_sidebar",

    events: {
        "click .disable": "disableJob",
        "click .enable": "enableJob",
        'click .edit_job': 'launchEditDialog'
    },

    disableJob: function(e) {
        e && e.preventDefault();
        this.model.save({enabled: false}, { wait: true });
    },

    enableJob: function(e) {
        e && e.preventDefault();
        this.model.save( {enabled: true}, { wait: true} );
    },

    additionalContext: function () {
        return this.model ? {
            enabled: this.model.get('state') !== 'disabled'
        } : {};
    },

    launchEditDialog: function (e) {
        e && e.preventDefault();
        new chorus.dialogs.EditJob({model: this.model}).launchModal();
    }
});