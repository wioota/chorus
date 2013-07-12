chorus.models.HdfsDataset = chorus.models.WorkspaceDataset.extend({
    constructorName: "HdfsDataset",

    urlTemplate: function(options) {
        var method = options && options.method;
        if(method === "create" || method === "update") {
            var base = "hdfs_datasets/";

            var completeUrl = this.id ? base + this.id : base;
            return completeUrl;
        } else {
            return "datasets/{{id}}";
        }
    },

    showUrlTemplate: "workspaces/{{workspace.id}}/hadoop_datasets/{{id}}",

    initialize: function () {
        this._super('initialize');
        this.attributes.entitySubtype = "HDFS";
    },

    dataSource: function() {
        return new chorus.models.HdfsDataSource(this.get("hdfsDataSource"));
    },

    content: function () {
        return this.get('content');
    }
});