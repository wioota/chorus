chorus.views.TagBox = chorus.views.Base.extend({
    templateName: "tag_box",
    constructorName: "TagBoxView",
    subviews: {'.tags_input': 'tagsInput'},
    events: {
        "click .save_tags": "saveTags"
    },

    setup: function() {
        this.bindings.add(this.model, "loaded", this.modelLoaded);
        this.tags = this.model.tags();
        this.tagsInput = new chorus.views.TagsInput({tags: this.tags, editing: false});
        this.bindings.add(this.tagsInput, "startedEditing", this.startedEditing);
        this.bindings.add(this.tagsInput, "finishedEditing", this.finishedEditing);
    },

    modelLoaded: function() {
        this.tags.reset(this.model.get("tags"));
    },

    startedEditing: function() {
        this.editing = true;
        this.render();
    },

    finishedEditing: function() {
        this.tags.save();
        this.editing = false;
        this.render();
    },

    saveTags: function(e) {
        e.preventDefault();
        this.tagsInput.finishEditing();
    }
});
