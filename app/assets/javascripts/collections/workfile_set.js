chorus.collections.WorkfileSet = chorus.collections.LastFetchWins.include(
    chorus.Mixins.CollectionFetchingSearch
).extend({
    constructorName: "WorkfileSet",
    model: chorus.models.DynamicWorkfile,
    urlTemplate: "workspaces/{{workspaceId}}/workfiles",
    showUrlTemplate: "workspaces/{{workspaceId}}/workfiles",
    searchAttr: "namePattern",

    urlParams: function() {
        return {
            namePattern: this.attributes.namePattern,
            fileType: this.attributes.fileType
        };
    }
});
