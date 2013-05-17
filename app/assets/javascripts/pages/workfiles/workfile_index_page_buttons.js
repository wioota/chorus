chorus.views.WorkfileIndexPageButtons = chorus.views.Base.extend({
    templateName: "workfile_index_page_buttons",

    events: {
        "click button.import_workfile": "launchWorkfileImportsDialog"
    },

    setup: function() {
        this.model.fetchIfNotLoaded();
    },

    postRender: function() {
        this.menu(this.$('.new_workfile'), {
            content: this.$(".create_workfile_menu"),
            orientation: "right",
            contentEvents: {
                "a.create_sql_workfile": this.launchWorkfileSqlNewDialog
            }
        });
    },

    canUpdate: function() {
        return this.model.loaded && this.model.canUpdate() && this.model.isActive();
    },

    additionalContext: function() {
        return {
            canUpdate: this.canUpdate()
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