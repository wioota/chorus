chorus.collections.WorkfileSet = chorus.collections.Base.extend({
    constructorName: "WorkfileSet",
    model: chorus.models.DynamicWorkfile,
    urlTemplate: "workspaces/{{workspaceId}}/workfiles",
    showUrlTemplate: "workspaces/{{workspaceId}}/workfiles",

    urlParams: function() {
        return {
            namePattern: this.attributes.namePattern,
            fileType: this.attributes.fileType
        };
    },

    search: function (term) {
        var self = this;
        self.attributes.namePattern = term;
        self.fetch({silent: true, success: function() { self.trigger('searched'); }});
    }
});
