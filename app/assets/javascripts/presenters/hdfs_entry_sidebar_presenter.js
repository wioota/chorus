chorus.presenters.HdfsEntrySidebar = chorus.presenters.Base.extend({
    entityId: function() {
        return this.resource && this.resource.id;
    },

    lastUpdatedStamp: function() {
        return t("hdfs.last_updated", { when : Handlebars.helpers.relativeTimestamp(this.resource && this.resource.get("lastUpdatedStamp"))});
    },

    fileName: function() {
        return this.resource && this.resource.get("name");
    },

    canCreateExternalTable: function() {
        return this.resource && this.resource.loaded && !this.resource.get("isBinary") && !this.resource.serverErrors;
    },

    canCreateWorkFlows: function() {
        return this.workFlowsEnabled() && this.options.hdfsDataSource && this.options.hdfsDataSource.get('supportsWorkFlows');
    }
});