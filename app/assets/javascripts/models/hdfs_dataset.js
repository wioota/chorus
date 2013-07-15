chorus.models.HdfsDataset = chorus.models.WorkspaceDataset.extend({
    constructorName: "HdfsDataset",

    urlTemplate: function(options) {
        var method = options && options.method;
        if(method === "create" || method === "update") {
            var base = "hdfs_datasets/";

            var completeUrl = this.id ? base + this.id : base;
            return completeUrl;
        } else {
            return "workspaces/{{workspace.id}}/datasets/{{id}}";
        }
    },

    iconUrl: function(options) {
        var size = (options && options.size) || "large";
        return "/images/hdfs_dataset_" + size + ".png";
    },

    showUrlTemplate: "workspaces/{{workspace.id}}/hadoop_datasets/{{id}}",

    initialize: function () {
        this._super('initialize');
        this.attributes.entitySubtype = "HDFS";
    },

    dataSource: function() {
        return new chorus.models.HdfsDataSource(this.get("hdfsDataSource"));
    },

    content: function() {
        return (this.get("content") && this.get("content").join("\n")) || "";
    },

    asWorkspaceDataset: function() {
        return this;
    }
});