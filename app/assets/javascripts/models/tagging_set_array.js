chorus.models.TaggingSetArray = chorus.models.Base.extend({
    urlTemplate: 'taggings',
    constructorName: "TaggingSetArray",

    save: function() {
        var setArray = _.map(this.get("taggingSets"), function(taggingSet) {
            var entity = taggingSet.attributes.entity;
            return {
                entityId: entity.id,
                entityType: entity.entityType,
                tagNames: taggingSet._tagNames()
            };
        });

        var saver = new chorus.models.Base();
        saver.urlTemplate = "taggings";
        this.listenTo(saver, "saved", _.bind(function() {
            this.trigger("saved");
        }, this));
        this.listenTo(saver, "saveFailed", _.bind(function(saverWithServerError) {
            this.trigger("saveFailed", saverWithServerError);
        }, this));
        saver.save({taggings: setArray});
    }
});