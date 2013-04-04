chorus.models.TaggingsUpdater = chorus.models.Base.extend({
    urlTemplate: 'taggings', // backbone requires something here
    constructorName: "TaggingsUpdater",

    updateTags: function(options) {
        var tagging = this.createTagging(options);
        this.pushTaggingOntoQueue(tagging);
    },

    createTagging: function(options) {
        var tagging = new chorus.models.Base();
        tagging.urlTemplate = "taggings";
        this.addEventListeners(tagging);
        var taggables = this.getTaggableEntities();

        var attributes = {taggables: taggables};
        var method = options.add ? 'add' : 'remove';
        attributes[method] = options[method].name();
        tagging.set(attributes);
        return tagging;
    },

    addEventListeners: function(tagging) {
        this.listenTo(tagging, "saved", _.bind(function() {
            this.saveNextTaggingFromQueue();
            this.trigger("updated");
        }, this));

        this.listenTo(tagging, "saveFailed", _.bind(function(saverWithServerError) {
            var tagName = this.queue[0].get('add') || this.queue[0].get('remove');
            chorus.toast("tag_update_failed", {tagName: tagName, toastOpts: {theme: "bad_activity"}});
            this.saveNextTaggingFromQueue();
            this.trigger("updateFailed", saverWithServerError);
        }, this));
    },

    getTaggableEntities: function() {
        return this.get("collection").map(function(model) {
            return {
                entityId: model.id,
                entityType: model.get('entityType')
            };
        });
    },

    pushTaggingOntoQueue: function(tagging) {
        // ensure that only one save happens at a time
        this.queue = this.queue || [];

        this.queue.push(tagging);
        if (this.queue.length===1) {
            tagging.save();
        }
    },

    saveNextTaggingFromQueue: function() {
        this.queue.shift(); // note that the last tagging has finished saving by removing it
        if(this.queue.length > 0) {
            this.queue[0].save(); // start saving the next tagging
        }
    }
});