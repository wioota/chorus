chorus.models.Tag = chorus.models.Base.extend({
    constructorName: 'Tag',
    matches: function(tagName) {
        return _.strip(this.get('name').toLowerCase()) === _.strip(tagName.toLowerCase());
    }
});