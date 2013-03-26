chorus.views.HdfsEntryItem = chorus.views.Base.extend(chorus.Mixins.TagsContext).extend({
    constructorName: "HdfsEntryItemView",
    templateName: "hdfs_entry",
    tagName: "li",

    additionalContext: function() {
        var message;
        var isDir = this.model.get("isDir");
        if(isDir)
        {
            if(this.model.get("count") < 0) {
                message = t("hdfs.directory_files.no_permission");
            } else {
                message = t("hdfs.directory_files", {count: this.model.get("count")});
            }
        } else {
            message = I18n.toHumanSize(this.model.get("size"));
        }
        var url = this.model.get("isBinary") ? undefined : this.model.showUrl();

        return {
            iconUrl: isDir ?
                "/images/data_sources/hadoop_directory_large.png" :
                chorus.urlHelpers.fileIconUrl(_.last(this.model.get("name").split("."))),
            url: url,
            displayableFiletype: this.model.get('isBinary') === false,
            tags: this.model.tags().models,
            fileInfo: message
        };
    }
});
