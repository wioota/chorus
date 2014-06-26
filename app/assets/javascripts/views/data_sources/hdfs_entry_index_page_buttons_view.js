chorus.views.HdfsEntryIndexPageButtons = chorus.views.Base.extend({
    constructorName: "HdfsEntryIndexPageButtonsView",
    templateName: "hdfs_entry_index_page_buttons",

    events: {
        "click .add_data": "launchImport"
    },

    setup: function () {
        this.model.fetchIfNotLoaded();
    },

    render: function () {
        if (this.model && this.model.loaded) {
            this._super("render", arguments);
        }
    },

    launchImport: function (e) {
        e && e.preventDefault();

        new chorus.dialogs.HdfsImportDialog({
            hdfsEntry: this.model
        }).launchModal();
    }
});
