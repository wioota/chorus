chorus.views.JobsIndexPageButtons = chorus.views.Base.extend({
    constructorName: "JobIndexPageButtons",
    templateName: "jobs_index_page_buttons",

    events: {
        'click button.create_job': 'launchCreateJobDialog'
    },

    setup: function() {
        this.model.fetchIfNotLoaded();
    },

    canUpdate: function() {
        return this.model.loaded && this.model.canUpdate() && this.model.isActive();
    },

    launchCreateJobDialog: function () {
        var dialog = new chorus.dialogs.ConfigureJob({ workspace: {id: this.model.id} });
        dialog.launchModal();
    },

    additionalContext: function() {
        return {
            canUpdate: this.canUpdate()
        };
    }
});
