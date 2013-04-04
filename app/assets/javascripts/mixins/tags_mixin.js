chorus.Mixins.Taggable = {

    hasTags: function() {
        return this.tags().length > 0;
    },

    tags: function() {
        if(!this.loaded) {
            return new chorus.collections.TaggingSet([], {entity: this});
        }

        if(!this._tags) {
            this._tags = new chorus.collections.TaggingSet(this.get('tags'), {entity: this});
            this.listenTo(this._tags, "all", function() {
                this.trigger("change");
            });
        }
        return this._tags;
    },

    updateTags: function(options) {
        if (!this.taggingsUpdater) {
            this.taggingsUpdater = new chorus.models.TaggingsUpdater({
                collection: new chorus.collections.Base([this])
            });

            this.listenTo(this.taggingsUpdater, 'updateFailed', function() {
                this.tags().fetchAll();
            });
        }
        this.taggingsUpdater.updateTags(options);
    }
};