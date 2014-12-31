chorus.views.WorkspaceSnapshot = chorus.views.Base.extend({
    constructorName: "WorkspaceSnapshotView",
    templateName: "workspace_snapshot",

    events: {},

    setup: function () {
        if (this.model.get('latestStatusChangeActivity')) {
            var activity = new chorus.models.Activity(this.model.get('latestStatusChangeActivity'));
            this.statusChangeActivityView = new chorus.views.Activity({model: activity, isReadOnly: true});
        }
    },

    postRender: function () {},

    additionalContext: function () {
        return {
            ownerName: this.model.owner().displayName(),
            ownerShowUrl: this.model.owner().showUrl(),
            projectStatusKey: 'workspace.project.status.' + this.model.get('projectStatus'),
            statusReason: this.model.get('projectStatusReason'),
            limitMilestones: chorus.models.Config.instance().license().limitMilestones(),
            milestoneProgress: this.model.milestoneProgress(),
            milestonesUrl: this.model.milestonesUrl()
        };
    },

});
