chorus.dialogs.EditTags = chorus.dialogs.Base.extend({
    constructorName: "EditTagsDialog",
    templateName: "edit_tags",
    title: t("edit_tags.title"),
    persistent: true,

    subviews: {
        ".tags_input": "tagsInput"
    },

    setup: function() {
        this.collection.each(function(model) {
            this.bindings.add(model.tags(), "saved", _.bind(this.saveSuccess, this, model));
            this.bindings.add(model.tags(), "saveFailed", this.saveFailed);
        }, this);
        var tags = this.tags();
        this.bindings.add(tags, "add", this.addTag);
        this.bindings.add(tags, "remove", this.removeTag);
        this.tagsInput = new chorus.views.TagsInput({tags: tags, displayCount: true});
    },

    addTag: function(tag) {
        tag.set('count', this.collection.length);
        this.collection.each(function(model) {
            model.tags().add(tag);
        });
        this.collection.saveTags();
    },

    removeTag: function(tag) {
        this.collection.each(function(model) {
            var tagToRemove = model.tags().where({name: tag.name()});
            model.tags().remove(tagToRemove);
        });
        this.collection.saveTags();
    },

    tags: function() {
        if(!this._tags) {
            var attributeHash = this.getTagCounts(this.collection);
            this._tags = new chorus.collections.TaggingSet(attributeHash);
        }
        return this._tags;
    },

    getTagCounts: function (collection) {
        var tagHash = {};

        collection.each(function(model){
            model.tags().each(function(tag){
                tagHash[tag.get('name')] = tagHash[tag.get('name')] + 1 || 1;
            });
        });

        return _.map(tagHash, function(value, key) {
            return { name : key, count: value };
        });
    },

    saveSuccess: function(savedModel) {
        savedModel.saved = true;
        savedModel.trigger("change");
        var allSaved = this.collection.every(function(model) {
            return model.saved;
        });
    },

    saveFailed: function(tags) {
        this.showErrors(tags);
    },

    revealed: function() {
        this._super("revealed", arguments);
        $("#facebox").css("overflow", "visible");
        this.tagsInput.focusInput();
    }
});