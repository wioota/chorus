chorus.views.WorkspaceDatasetIndexPageButtons = chorus.views.Base.extend({

    constructorName: "WorkspaceDatasetIndexPageButtonsView",

    templateName: "workspace_dataset_index_page_buttons",

    createActions: [
        {className: 'import_file', text: t("actions.import_file")},
        {className: 'create_file_mask', text: t("actions.create_file_mask")}
    ],

    menuEvents: {
        "a.import_file": function(e) {
            e && e.preventDefault();
            new chorus.dialogs.FileImport({workspaceId: this.model.get('id')}).launchModal();
        },
        "a.create_file_mask": function(e) {
            e && e.preventDefault();
            new chorus.dialogs.CreateFileMask({workspace: this.model}).launchModal();
        }
    },

    setup: function() {
        this.model.fetchIfNotLoaded();
    },

    postRender: function() {
        this.menu(this.$('.add_data'), {
            content: this.$(".add_data_menu"),
            orientation: "right",
            contentEvents: this.menuEvents
        });
    },

    additionalContext: function() {
        return {
            canUpdate: this.canUpdate(),
            createActions: this.createActions
        };
    },

    canUpdate: function() {
        return this.model.loaded && this.model.canUpdate() && this.model.isActive();
    }
});