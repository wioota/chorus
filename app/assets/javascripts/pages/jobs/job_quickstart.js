chorus.views.JobQuickstart = chorus.views.Base.extend({
    constructorName: "JobQuickstartView",
    templateName: "job_quickstart",
    additionalClass: "job_show quickstart",

    events: {
        'click a.new_import_source_data.dialog': 'launchCreateImportSourceDataTaskDialog',
        'click a.new_run_work_flow.dialog': 'launchCreateFlowTaskDialog'
    },

    launchCreateImportSourceDataTaskDialog: function (e) {
        e && e.preventDefault();
        new chorus.dialogs.ConfigureImportSourceDataTask({job: this.model}).launchModal();
    },

    launchCreateFlowTaskDialog: function(e) {
        e && e.preventDefault();
        var workFlows = new chorus.collections.WorkfileSet([], {fileType: 'work_flow', workspaceId: this.model.workspace().get("id")});
        new chorus.dialogs.ConfigureWorkfileTask({job: this.model, collection: workFlows}).launchModal();
    }
});
