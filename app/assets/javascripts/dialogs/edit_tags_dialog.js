chorus.dialogs.EditTags = chorus.dialogs.Base.extend({
    constructorName: "EditTagsDialog",
    templateName: "edit_tags",
    title: t("edit_tags.title"),
    persistent: true,

    events: {
        "click .submit": "saveTags"
    },

    subviews: {
        ".tags_input": "tagsInput"
    },

    setup: function() {
        this.collection.each(function(model) {
            this.bindings.add(model.tags(), "saved", _.bind(this.saveSuccess, this, model));
            this.bindings.add(model.tags(), "saveFailed", this.saveFailed);
            model.editableTags = model.tags().clone();
        }, this);
        var tags = this.tags();
        this.bindings.add(tags, "add", this.addTag);
        this.bindings.add(tags, "remove", this.removeTag);
        this.tagsInput = new chorus.views.TagsInput({tags: tags, editing: true});
        this.bindings.add(this.tagsInput, "finishedEditing", this.finishedEditing);
    },

    addTag: function(tag) {
        this.collection.each(function(model) {
            model.editableTags.add(tag);
        });
    },

    removeTag: function(tag) {
        this.collection.each(function(model) {
            var tagToRemove = model.editableTags.where({name: tag.name()});
            model.editableTags.remove(tagToRemove);
        });
    },

    tags: function() {
        if(!this._tags) {

            var tagNames = this.collection.map(function(model) {
                return model.editableTags.pluck("name");
            });
            tagNames = _.uniq(_.flatten(tagNames));

            var tagsHash = _.map(tagNames, function(tagName) {
                return {name: tagName};
            });

            this._tags = new chorus.collections.TaggingSet(tagsHash);
        }
        return this._tags;
    },

    saveTags: function() {
        this.tagsInput.finishEditing();
    },

    finishedEditing: function() {
        this.$("button.submit").startLoading("actions.saving");
        this.collection.each(function(model) {
            model.saved = false;
            model.tags().reset(model.editableTags.models);
        });

        this.collection.saveTags();
    },

    saveSuccess: function(savedModel) {
        savedModel.saved = true;
        savedModel.trigger("change");
        var allSaved = this.collection.every(function(model) {
            return model.saved;
        });
        if(allSaved) {
            this.closeModal();
        }
    },

    saveFailed: function(tags) {
        this.$(".submit").stopLoading();
        this.showErrors(tags);
    },

    closeModal: function() {
        this.collection.each(function(model) {
            delete model.editableTags;
        }, this);
        this._super("closeModal", arguments);
    },

    revealed: function() {
        this._super("revealed", arguments);
        $("#facebox").css("overflow", "visible");
        this.tagsInput.focusInput();
    }
});