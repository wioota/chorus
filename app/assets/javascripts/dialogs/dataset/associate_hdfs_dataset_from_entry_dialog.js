//= require ./hdfs_dataset_attributes_dialog.js

chorus.dialogs.AssociateHdfsDatasetFromEntry = chorus.dialogs.HdfsDatasetAttributes.extend({
    constructorName: 'AssociateHdfsDatasetFromEntryDialog',
    title: t('associate_hdfs_dataset_from_entry.title'),

    findModel: function () {
        return new chorus.models.HdfsDataset();
    },

    postRender: function() {
        this.$("input.name").val(this.options.entry.get('name'));
        this.$("input.file_mask").val(this.options.entry.get('path'));
    }
});