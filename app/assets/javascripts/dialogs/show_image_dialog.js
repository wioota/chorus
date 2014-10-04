chorus.dialogs.ShowImage = chorus.dialogs.Base.extend({
    constructorName: "ShowImageDialog",
    templateName: "show_image",
    persistent: true,

    events: {
        "click .add_note" : "launchNotesNewDialog",
        "click .copy": "launchCopyWorkfileDialog",
        "click .edit_tags": "startEditingTags",
        "click .rename": "launchRenameDialog",
        "click .delete_workfile": "launchWorkfileDeleteDialog"
    },

    setup: function(options) {
        this.activity = options.activity;
        this.originalModule = options.originalModule;
        this.title = this.activity.get("workfile").fileName;
        this.model = new chorus.models.Workfile(this.activity.get("workfile"));
    },

    additionalContext:function () {
        return {
            imageUrl: this.activity.get("workfile").versionInfo.contentUrl,
            downloadUrl: this.model.downloadUrl(),
            workspaceIconUrl: this.model.workspace().defaultIconUrl('small'),
            workspaceShowUrl: this.model.workspace().showUrl(),
            workspaceName: this.model.workspace().name()
        };
    },

    launchWorkfileDeleteDialog: function(e) {
        e && e.preventDefault();
        var alert = new chorus.alerts.WorkfileDelete({
            workfileId: this.model.id,
            workspaceId: this.model.workspace().id,
            workfileName: this.model.get("fileName")
        });
        alert.redirectUrl = null;
        alert.launchNewModal();
        this.attachCloseModalEvent();
    },

    launchRenameDialog: function(e) {
        e && e.preventDefault();
        new chorus.dialogs.RenameWorkfile({model: this.model}).launchNewModal();
        this.attachCloseModalEvent();
    },

    startEditingTags: function(e) {
        e.preventDefault();
        new chorus.dialogs.EditTags({collection: new chorus.collections.Base([this.model])}).launchNewModal();
        this.attachCloseModalEvent();
    },

    launchNotesNewDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.NotesNew({
            pageModel: this.model,
            entityId: this.model.id,
            entityType: "workfile",
            workspaceId: this.model.workspace().id,
            allowWorkspaceAttachments: true
        });
        dialog.launchNewModal();
        this.attachCloseModalEvent();
    },

    launchCopyWorkfileDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.CopyWorkfile({
            workfileId: this.model.id,
            workspaceId: this.model.workspace().id,
            activeOnly: true
        });
        dialog.launchNewModal();
        this.attachCloseModalEvent();
    },

    attachCloseModalEvent: function() {
        $(document).one("close.faceboxsuccess", _.bind(function(){
                this.setup();
                this.render();
            },
            this.originalModule));
    }

});
