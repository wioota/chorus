chorus.models.Tag = chorus.models.Base.extend({
    constructorName: 'Tag',
    urlTemplate: "tags/{{id}}",
    showUrlTemplate: function(workspaceId) {
        if(workspaceId) {
            return "workspaces/" + workspaceId + "/tags/{{encode name}}";
        } else {
            return "tags/{{encode name}}";
        }
    },
    matches: function(tagName) {
        return _.strip(this.get('name').toLowerCase()) === _.strip(tagName.toLowerCase());
    }
});