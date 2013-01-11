chorus.views.TagBox = chorus.views.Base.extend({
    templateName: "tag_box",
    constructorName: "TagBoxView",
    subviews: {'.tags_input': 'tagsInput'},

    setup: function() {
        this.bindings.add(this.model, "loaded", this.modelLoaded);
        this.tags = this.model.tags();
        this.tagsInput = new chorus.views.TagsInput({tags: this.tags});
        this.bindings.add(this.tags, "add", this.saveTags);
        this.bindings.add(this.tags, "remove", this.saveTags);
    },

    modelLoaded: function() {
        this.tags.reset(this.model.get("tags"));
    },

    saveTags: function() {
        this.tags.save();
    }
});
