chorus.collections.CsvHdfsFileSet = chorus.collections.HdfsEntrySet.extend({
    constructorName: "CsvHdfsFileSet",
    model: chorus.models.HdfsExternalTable,

    filesOnly: function() {
        var nonTextFiles = _.filter(this.models, function(hdfsEntry) {
            return hdfsEntry.get("isDir");
        });

        return this.remove(nonTextFiles);
    }
});