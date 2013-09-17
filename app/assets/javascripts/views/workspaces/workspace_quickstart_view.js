chorus.views.WorkspaceQuickstart = chorus.views.Base.extend({
    constructorName: "WorkspaceQuickstartView",
    templateName: "workspace_quickstart",
    additionalClass: "workspace_show quickstart",
    useLoadingSection: true,

    events: {
        "click a.dismiss": "visitShowPage",
        "click .import_workfiles": 'launchImportWorkfilesDialog',
        "click .edit_workspace": 'launchEditWorkspaceDialog',
        "click .edit_workspace_members": 'launchWorkspaceEditMembersDialog',
        "click .new_sandbox": 'launchSandboxNewDialog'
    },

    additionalContext: function() {
        return {
            workspaceUrl: this.model.showUrl(),
            needsMember: !this.model.get("hasAddedMember"),
            needsWorkfile: !this.model.get("hasAddedWorkfile"),
            needsSandbox: !this.model.get("hasAddedSandbox"),
            needsSettings: !this.model.get("hasChangedSettings")
        };
    },

    setup: function() {
        this.subscribePageEvent("modal:closed", this.dismissQuickStart);
    },

    dismissQuickStart: function() {
        this.model.fetch();
    },

    render: function() {

        if (this.model.get("hasAddedMember") === true &&
            this.model.get("hasAddedSandbox") === true &&
            this.model.get("hasAddedWorkfile") === true &&
            this.model.get("hasChangedSettings") === true) {

            chorus.router.navigate(this.model.showUrl());
        }

        this._super("render", arguments);
    },

    visitShowPage: function(e) {
        var quickstart = new chorus.models.WorkspaceQuickstart({
            workspaceId: this.model.get("id")
        });
        quickstart.destroy();

        e && e.preventDefault();
        chorus.router.navigate($(e.currentTarget).attr("href"));
    },

    launchEditWorkspaceDialog: function (e) {
        e && e.preventDefault();

        this.editWorkspaceDialog = new chorus.dialogs.EditWorkspace({model: this.model});
        this.onceLoaded(this.model.members(), function () {
            this.editWorkspaceDialog.launchModal();
        });
    },

    launchSandboxNewDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.SandboxNew({workspaceId: this.model.id, noReload: true});
        dialog.launchModal();
    },

    launchWorkspaceEditMembersDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.WorkspaceEditMembers({pageModel: this.model});
        dialog.launchModal();
    },

    launchImportWorkfilesDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.WorkfilesImport({workspaceId: this.model.id});
        dialog.launchModal();
    }
});
