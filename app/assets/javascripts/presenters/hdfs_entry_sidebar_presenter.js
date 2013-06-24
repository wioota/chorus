chorus.presenters.HdfsEntrySidebar = chorus.presenters.Base.extend({
    entityId: function() {
        return this.resource && this.resource.id;
    },

    lastUpdatedStamp: function() {
        return t("hdfs.last_updated", { when : Handlebars.helpers.relativeTimestamp(this.resource && this.resource.get("lastUpdatedStamp"))});
    }
});