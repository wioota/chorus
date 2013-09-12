chorus.views.ProjectStatus = chorus.views.Base.extend({
    constructorName: "ProjectStatus",
    templateName: "project_status",

    events: {
        "click .edit_project_status": 'launchEditProjectStatusDialog'
    },

    additionalContext: function () {
        return {
            projectStatusKey: 'workspace.project.status.' + this.model.get('projectStatus')
        };
    },

    launchEditProjectStatusDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.EditProjectStatus({
            model: this.model
        });
        dialog.launchModal();
    }
});