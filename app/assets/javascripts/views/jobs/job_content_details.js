chorus.views.JobContentDetails = chorus.views.Base.extend({
    templateName: "job_content_details",
    constructorName: 'JobContentDetails',

    events: {
        "click button.toggle_enabled": "toggleEnabled",
        "click button.edit_schedule": "launchEditDialog"
    },

    createActions: [
        {className: 'import_source_data', text: t("job_task.action.import_source_data")}
    ],

    menuEvents: {
        "a.import_source_data": function(e) {
            this.launchCreateImportSourceDataTaskDialog(e);
        }
    },

    setup: function() {
        chorus.applyPlugins(this);
        this.model.fetchIfNotLoaded();
        this.workspace = this.model.workspace();
    },

    postRender: function () {
        this.menu(this.$(".create_task"), {
            content: this.$(".create_task_menu"),
            orientation: "right",
            contentEvents: this.menuEvents
        });
    },

    launchCreateImportSourceDataTaskDialog: function (e) {
        e && e.preventDefault();
        new chorus.dialogs.ConfigureImportSourceDataTask({job: this.model}).launchModal();
    },

    launchEditDialog: function (e) {
        e && e.preventDefault();
        new chorus.dialogs.EditJob({model: this.model}).launchModal();
    },

    toggleEnabled: function () {
        this.$("button.toggle_enabled").text(t("job.actions.saving")).prop("disabled", true);
        this.model.toggleEnabled();
    },

    additionalContext: function() {
        return {
            canUpdate: this.canUpdate(),
            enabledButtonLabel: this.enabledButtonLabel(),
            actionBarClass: this.actionBarClass(),
            createActions: this.createActions
        };
    },

    canUpdate: function() {
        return this.workspace.canUpdate() && this.workspace.isActive();
    },

    enabledButtonLabel: function () {
        return this.model.get("enabled") ? 'job.actions.disable' : 'job.actions.enable';
    },

    actionBarClass: function () {
        return this.model.get("enabled") ? 'action_bar_highlighted' : 'action_bar_limited';
    }
});
