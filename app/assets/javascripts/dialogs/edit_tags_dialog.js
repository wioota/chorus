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
        this.tagsInput = new chorus.views.TagsInput({tags: tags});
    },

    addTag: function(tag) {
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
            var tagNames = this.collection.map(function(model) {
                return model.tags().pluck("name");
            });
            tagNames = _.uniq(_.flatten(tagNames));

            var tagsHash = _.map(tagNames, function(tagName) {
                return {name: tagName};
            });

            this._tags = new chorus.collections.TaggingSet(tagsHash);
        }
        return this._tags;
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