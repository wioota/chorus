chorus.views.WorkfileIndexPageButtons = chorus.views.Base.extend({
    templateName: "workfile_index_page_buttons",

    events: {
        "click button.import_workfile": "launchWorkfileImportsDialog",
        "click button.new_workfile": "launchWorkfileSqlNewDialog"
    },

    setup: function() {
        this.model.fetchIfNotLoaded();
    },

    additionalContext: function() {
        return {
            canUpdate: this.model.loaded && this.model.canUpdate() && this.model.isActive()
        };
    },

    launchWorkfileImportsDialog: function(e) {
        e && e.preventDefault();
        new chorus.dialogs.WorkfilesImport({workspaceId: this.model.get('id')}).launchModal();
    },

    launchWorkfileSqlNewDialog: function(e) {
        e && e.preventDefault();
        new chorus.dialogs.WorkfilesSqlNew({workspaceId: this.model.get('id')}).launchModal();
    }
});