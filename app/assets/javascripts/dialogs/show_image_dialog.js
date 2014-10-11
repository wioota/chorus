chorus.dialogs.ShowImage = chorus.dialogs.Base.extend({
    constructorName: "ShowImageDialog",
    templateName: "show_image",
    persistent: true,

    events: {
        "click .add_note" : "launchNotesNewDialog",
        "click .add_comment" : "launchCommentNewDialog",
        "click .copy": "launchCopyWorkfileDialog",
        "click .edit_tags": "startEditingTags",
        "click .rename": "launchRenameDialog",
        "click .delete_workfile": "launchWorkfileDeleteDialog"
    },

    setup: function(options) {
        this.activity = options.activity;
        this.originalModule = options.originalModule;
        this.attachment = options.attachment;
        if(this.attachment) {
            this.title = this.attachment.name();
            this.model = new chorus.models.Attachment(this.attachment);
        }
        else {
            this.title = this.activity.get("workfile").fileName;
            this.model = new chorus.models.Workfile(this.activity.get("workfile"));
        }
    },

    postRender: function() {
        this.$('.main_image').load(_.bind(function(){
            this.centerHorizontally();
        }, this));
    },

    additionalContext:function () {
        var imageUrl;
        var showFullOptions = true;
        if(this.attachment) {
            imageUrl = this.model.contentUrl();
            showFullOptions = false;
        }
        else {
            imageUrl = this.activity.get("workfile").versionInfo.contentUrl;
        }
        return {
            imageUrl: imageUrl,
            downloadUrl: this.model.downloadUrl(),
            workspaceIconUrl: this.model.workspace().defaultIconUrl('small'),
            workspaceShowUrl: this.model.workspace().showUrl(),
            workspaceName: this.model.workspace().name(),
            showFullOptions: showFullOptions
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

    launchCommentNewDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.Comment({
            pageModel: this.activity,
            eventId: this.activity.id
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
