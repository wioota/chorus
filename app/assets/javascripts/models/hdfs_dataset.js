chorus.models.HdfsDataset = chorus.models.WorkspaceDataset.extend({
    constructorName: "HdfsDataset",
    urlTemplate: "hdfs_datasets",

    initialize: function () {
        this._super('initialize');
        this.attributes.entitySubtype = "HDFS";
    },

    dataSource: function() {
        return new chorus.models.HdfsDataSource(this.get("hdfsDataSource"));
    }
});