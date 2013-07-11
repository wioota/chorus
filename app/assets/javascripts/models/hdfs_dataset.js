chorus.models.HdfsDataset = chorus.models.WorkspaceDataset.extend({
    constructorName: "HdfsDataset",

    urlTemplate: function(options) {
        var method = options && options.method;
        if(method === "create") {
            return "hdfs_datasets";
        } else {
            return "datasets/{{id}}";
        }
    },

    initialize: function () {
        this._super('initialize');
        this.attributes.entitySubtype = "HDFS";
    },

    dataSource: function() {
        return new chorus.models.HdfsDataSource(this.get("hdfsDataSource"));
    }
});