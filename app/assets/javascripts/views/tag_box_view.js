chorus.views.TagBox = chorus.views.Base.extend({
    templateName: "tag_box",
    constructorName: "TagBoxView",
    subviews: {'.tags_input': 'tagsInput'},

    setup: function() {
        this.requiredResources.add(this.model);
        this.tags = this.model.tags();
        this.tagsInput = new chorus.views.TagsInput({tags: this.tags});
        this.bindings.add(this.tagsInput, "tag:click", this.navigateToTagShowPage);
        this.bindings.add(this.tags, "add", this.addTag);
        this.bindings.add(this.tags, "remove", this.removeTag);
    },

   navigateToTagShowPage: function(tag) {
       // this ensures url fragment has an initial slash in browser address bar
       var url = tag.showUrl(this.options.workspaceIdForTagLink).replace("#","#/");
       chorus.router.navigate(url);
    },

    resourcesLoaded: function() {
        this.tags.reset(this.model.get("tags"));
    },

    addTag: function(model) {
        this.model.updateTags({add: model});
    },

    removeTag: function(model) {
        this.model.updateTags({remove: model});
    }
});
