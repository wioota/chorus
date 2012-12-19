chorus.Mixins.Tags = {

    hasTags: function() {
        return this.tags().length > 0;
    },

    tags: function() {
        if(!this.loaded) {
            return new chorus.collections.TagSet([], {entity: this})
        }

        if(!this._tags) {
            this._tags = new chorus.collections.TagSet(this.get('tags'), {entity: this});
        }
        return this._tags;
    }
};