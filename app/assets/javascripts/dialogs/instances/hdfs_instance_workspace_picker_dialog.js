chorus.dialogs.HdfsInstanceWorkspacePicker = chorus.dialogs.PickWorkspace.extend({
    constructorName: "HdfsInstanceWorkspacePicker",

    title: t("hdfs_instance.workspace_picker.title"),
    submitButtonTranslationKey: "hdfs_instance.workspace_picker.button",

    setup: function() {
        this.requiredResources.add(this.collection);
        this._super("setup", arguments);
        chorus.PageEvents.subscribe("csv_import:started", this.closeDialog, this);
    },

    resourcesLoaded: function() {
        this.render();
    },

    closeDialog: function() {
        this.closeModal();
    },

    submit : function() {
        this.model.serverErrors = [];

        if(this.selectedItem().sandbox().instance().version() < "4.2") {
            this.showDialogError(t("hdfs_instance.gpdb_version.too_old_42"));
            return;
        }

        var path = this.model.get("path");
        var separator = (path === "/") ? "" : "/";

        this.hdfsFiles = new chorus.collections.CsvHdfsFileSet([], {
            hadoopInstance : this.model.get("hadoopInstance"),
            id: this.model.get("id")
        });
        this.hdfsFiles.bindOnce("loaded", this.launchCreateHdfsDialog, this);
        this.hdfsFiles.fetchAll();
        this.trigger("workspace:selected", this.selectedItem());
    },

    showDialogError : function(errorText) {
        this.model.serverErrors = errorText.serverErrors ? errorText.serverErrors : {fields: {not_a_real_field: {GENERIC: {message: errorText}}}};
        this.render();
    },

    launchCreateHdfsDialog: function() {
        var hdfsTextFiles = this.hdfsFiles.filesOnly();

        if (hdfsTextFiles.length === 0) {
            this.showDialogError(t("hdfs_instance.no_text_files"));
        } else {
            this.externalTableDialog = new chorus.dialogs.CreateDirectoryExternalTableFromHdfs({
                collection: hdfsTextFiles || [],
                directoryName: this.model.get("name"),
                workspaceId: this.selectedItem().id,
                workspaceName: this.selectedItem().get("name"),
                csvOptions: {
                    contents: hdfsTextFiles.models[0].get('contents')
                },
                hdfs_entry_id: this.model.get('id')
            });
            this.launchSubModal(this.externalTableDialog);
        }
    }
});
