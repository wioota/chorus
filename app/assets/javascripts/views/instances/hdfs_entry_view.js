chorus.views.HdfsEntry = chorus.views.Base.extend(chorus.Mixins.TagsContext).extend({
    templateName: "hdfs_entry",
    tagName: "li",

    additionalContext: function() {
        var message;
        if(this.model.get("count") < 0) {
            message = t("hdfs.directory_files.no_permission");
        } else {
            message = t("hdfs.directory_files", {count: this.model.get("count")});
        }

        return {
            humanSize: I18n.toHumanSize(this.model.get("size")),
            iconUrl: this.model.get("isDir") ?
                "/images/data_sources/hadoop_directory_large.png" :
                chorus.urlHelpers.fileIconUrl(_.last(this.model.get("name").split("."))),
            showUrl: this.model.showUrl(),
            dirInfo: message,
            displayableFiletype: this.model.get('isBinary') === false,
            tags: this.model.tags().models
        };
    }
});
