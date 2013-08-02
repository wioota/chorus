chorus.views.JobTaskSidebar = chorus.views.Sidebar.extend({
    constructorName: "JobTaskSidebar",
    templateName:"job_task_sidebar",

    events: {
        'click .delete_job_task': 'launchDeleteAlert',
        'click .edit_job_task': 'launchEditImportSourceDataTaskDialog'
    },

    launchDeleteAlert: function (e) {
        e && e.preventDefault();
        new chorus.alerts.JobTaskDelete({model: this.model}).launchModal();
    },

    launchEditImportSourceDataTaskDialog: function (e) {
        e && e.preventDefault();
        new chorus.dialogs.ConfigureImportSourceDataTask({model: this.model}).launchModal();
    }
});