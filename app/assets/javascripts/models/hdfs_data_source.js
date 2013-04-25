chorus.models.HdfsDataSource = chorus.models.AbstractDataSource.extend({
    constructorName: "HdfsDataSource",
    urlTemplate: "hdfs_data_sources/{{id}}",
    showUrlTemplate: "hdfs_data_sources/{{id}}/browse/",
    shared: true,
    entityType: "hdfs_data_source",

    isShared: function() {
        return true;
    },

    providerIconUrl: function() {
        return this._imagePrefix + "icon_hdfs_data_source.png";
    },

    isHadoop: function() {
        return true;
    },

    declareValidations: function(newAttrs) {
        this.require("name", newAttrs);
        this.requirePattern("name", chorus.ValidationRegexes.MaxLength64(), newAttrs);
        this.require("host", newAttrs);
        this.require("port", newAttrs);
        this.require("username", newAttrs);
        this.require("groupList", newAttrs);
        this.requirePattern("port", chorus.ValidationRegexes.OnlyDigits(), newAttrs);
    },

    sharedAccountDetails: function() {
        return this.get("username") + ", " + this.get("groupList");
    }

});
