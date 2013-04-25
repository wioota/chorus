chorus.models.HdfsEntry = chorus.models.Base.extend({
    constructorName: "HdfsEntry",
    nameAttribute: 'name',
    entityType: "hdfs_file",

    eventType: function() {
        return "hdfs_entry";
    },

    urlTemplate: function() {
        return "hdfs_data_sources/{{hdfsDataSource.id}}/files/{{id}}";
    },

    showUrlTemplate: function() {
        if(this.get("isDir")) {
            return "hdfs_data_sources/{{hdfsDataSource.id}}/browse/{{id}}";
        } else {
            return "hdfs_data_sources/{{hdfsDataSource.id}}/browseFile/{{id}}";
        }
    },

    getPath: function() {
        var encodedPath = encodeURIComponent((this.get("path") === "/") ? "" : this.get("path"));
        return encodedPath.replace(/%2F/g, "/");
    },

    getFullAbsolutePath: function() {
        return this.getPath() + '/' + this.name();
    },

    pathSegments: function() {
        return _.map(this.get("ancestors"), function(ancestor) {
            return new chorus.models.HdfsEntry(_.extend({isDir: true, hdfsDataSource: this.get("hdfsDataSource")}, ancestor));
        }, this).reverse();

    },

    parent: function() {
        return _.last(this.pathSegments());
    },

    getHdfsDataSource: function() {
        return new chorus.models.HdfsDataSource(this.get('hdfsDataSource')).set({ dataSourceProvider: "Hadoop" });
    },

    iconUrl: function() {
        var name = this.get("name") || "";
        return chorus.urlHelpers.fileIconUrl(_.last(name.split(".")));
    }
});
