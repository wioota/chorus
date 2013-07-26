chorus.views.JobShowPageButtons = chorus.views.Base.extend({
    constructorName: "JobShowPageButtons",
    templateName: "job_show_page_buttons",

    events: {
        "click button.create_task": "openCreateJobTaskDialog"
    },

    setup: function() {
        chorus.applyPlugins(this);
        this.model.fetchIfNotLoaded();
        this.workspace = this.model.workspace();
    },

    canUpdate: function() {
        return this.workspace.canUpdate() && this.workspace.isActive();
    },

    openCreateJobTaskDialog: function (e) {
        e && e.preventDefault();
        new chorus.dialogs.CreateJobTask({job: this.model}).launchModal();
    },

    additionalContext: function() {
        return {
            canUpdate: this.canUpdate()
        };
    }
});