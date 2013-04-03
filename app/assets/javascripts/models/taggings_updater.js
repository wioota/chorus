chorus.models.TaggingsUpdater = chorus.models.Base.extend({
    urlTemplate: 'taggings', // backbone requires something here
    constructorName: "TaggingsUpdater",

    updateTags: function(options) {
        var tagging = new chorus.models.Base();
        tagging.urlTemplate = "taggings";

        this.listenTo(tagging, "saved", _.bind(function() {
            this.saveNextFromQueue();
            this.trigger("saved");
        }, this));

        this.listenTo(tagging, "saveFailed", _.bind(function(saverWithServerError) {
            this.saveNextFromQueue();
            this.trigger("saveFailed", saverWithServerError);
        }, this));

        var taggables = this.get("collection").map(function (model) {
            return {
                entityId: model.id,
                entityType: model.get('entityType')
            };
        });

        var attributes = {taggables: taggables};
        var method = options.add ? 'add' : 'remove';
        attributes[method] = options[method].name();
        tagging.set(attributes);

        // ensure that only one save happens at a time
        this.queue = this.queue || [];

        this.queue.push(tagging);
        if (this.queue.length==1) {
            tagging.save()
        }
    },

    saveNextFromQueue: function() {
        this.queue.shift();
        if(this.queue.length > 0) {
            this.queue[0].save();
        }
    }
});