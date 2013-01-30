chorus.models.Tag = chorus.models.Base.extend({
    constructorName: 'Tag',
    urlTemplate: "tags/{{id}}",
    showUrlTemplate: "tags/{{encode name}}",
    matches: function(tagName) {
        return _.strip(this.get('name').toLowerCase()) === _.strip(tagName.toLowerCase());
    }
});