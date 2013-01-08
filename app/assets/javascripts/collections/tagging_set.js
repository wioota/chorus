chorus.collections.TaggingSet = chorus.collections.Base.extend({
    urlTemplate: 'taggings',
    model: chorus.models.Tag,
    constructorName: "TaggingSet",

    save: function() {
        var entityInfo = {entityId: this.attributes.entity.id, entityType: this.attributes.entity.entityType};
        new chorus.models.BulkSaver({collection: this}).save(_.extend(entityInfo, {tagNames: this._tagNames()}));
    },

    containsTag: function(tagName) {
        return this.any(function(tag) {
            return tag.name().toLowerCase() === tagName.toLowerCase();
        });
    },

    _tagNames: function() {
        return this.map(function(tag) {
            return tag.name();
        });
    }
});