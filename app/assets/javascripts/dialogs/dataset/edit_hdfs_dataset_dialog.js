//= require ./hdfs_dataset_attributes_dialog.js

chorus.dialogs.EditHdfsDataset = chorus.dialogs.HdfsDatasetAttributes.extend({
    constructorName: "EditHdfsDatasetDialog",
    title: t("edit_hdfs_dataset.title"),
    toastMessage: "edit_hdfs_dataset.toast",

    toastMessageParams: function () {
        return {};
    },

    findModel: function () {
        return this.options.model;
    }
});