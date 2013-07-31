chorus.views.JobTaskSidebar = chorus.views.Sidebar.extend({
    constructorName: "JobTaskSidebar",
    templateName:"job_task_sidebar",

    events: {
        'click .delete_job_task': 'launchDeleteAlert'
    },

    launchDeleteAlert: function (e) {
        e && e.preventDefault();
        new chorus.alerts.JobTaskDelete({model: this.model}).launchModal();
    }
});