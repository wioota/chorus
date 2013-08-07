chorus.views.JobTaskSidebar = chorus.views.Sidebar.extend({
    constructorName: "JobTaskSidebar",
    templateName:"job_task_sidebar",

    events: {
        'click .delete_job_task': 'launchDeleteAlert',
        'click .edit_job_task': 'launchTaskConfigurationDialog'
    },

    launchDeleteAlert: function (e) {
        e && e.preventDefault();
        new chorus.alerts.JobTaskDelete({model: this.model}).launchModal();
    },

    launchTaskConfigurationDialog: function (e) {
        e && e.preventDefault();
        if (this.model.get('action') === 'import_source_data') {
            new chorus.dialogs.ConfigureImportSourceDataTask({model: this.model}).launchModal();
        } else if (this.model.get('action') === 'run_work_flow') {
            var workFlows = new chorus.collections.WorkfileSet([], {fileType: 'work_flow', workspaceId: this.model.job().workspace().get("id")});
            new chorus.dialogs.ConfigureWorkFlowTask({model: this.model, collection: workFlows}).launchModal();
        }
    }
});