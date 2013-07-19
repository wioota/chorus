//= require ./hdfs_dataset_attributes_dialog.js

chorus.dialogs.AssociateHdfsDatasetFromEntry = chorus.dialogs.HdfsDatasetAttributes.extend({
    findModel: function () {
        return new chorus.models.HdfsDataset();
    }
});