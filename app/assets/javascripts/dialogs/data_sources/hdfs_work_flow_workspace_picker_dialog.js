chorus.dialogs.HdfsWorkFlowWorkspacePicker =  chorus.dialogs.PickWorkspace.extend({
    title: t("hdfs_data_source.workspace_picker.title"),
    submitButtonTranslationKey: "hdfs_data_source.workspace_picker.button",

    preInitialize: function() {
        this.options.activeOnly = true;
        this._super("preInitialize", arguments);
    },

    submit: function() {
        this.launchSubModal(new chorus.dialogs.WorkFlowNewForHdfsEntryList({
            workspace: this.selectedItem(),
            collection: this.options.hdfsEntries
        }));
    }
});