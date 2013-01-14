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
            return tag.matches(tagName);
        });
    },

    _tagNames: function() {
        return this.map(function(tag) {
            return tag.name();
        });
    },

    add: function(models, options){
        models = _.isArray(models) ? models.slice() : [models];
        models = _.reject(models, function(model){
            var name = model instanceof chorus.models.Base ? model.get('name') : model.name;
            return this.containsTag(name);
        }, this);
        this._super('add', [models, options]);
    }
});