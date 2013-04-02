chorus.models.TaggingsUpdater = chorus.models.Base.extend({
    urlTemplate: 'taggings',
    constructorName: "TaggingsUpdater",

    save: function() {
        var tagging = new chorus.models.Base();
        tagging.urlTemplate = "taggings";

        this.listenTo(tagging, "saved", _.bind(function() {
            this.trigger("saved");
        }, this));
        this.listenTo(tagging, "saveFailed", _.bind(function(saverWithServerError) {
            this.trigger("saveFailed", saverWithServerError);
        }, this));

        var taggables = this.get("collection").map(function (model) {
            return {
                entityId: model.id,
                entityType: model.get('entityType')
            };
        });

        var attributes = {taggables: taggables};
        var method = this.get('add') ? 'add' : 'remove';
        attributes[method] = this.get(method).name();
        tagging.save(attributes);
    }
});