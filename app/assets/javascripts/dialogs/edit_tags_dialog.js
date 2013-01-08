chorus.dialogs.EditTags = chorus.dialogs.Base.extend({
    constructorName: "EditTagsDialog",
    templateName: "edit_tags",
    title: t("edit_tags.title"),
    persistent: true,

    events: {
        "click .submit": "saveTags"
    },

    subviews: {
        ".tag_box_collection": "tagBoxCollection"
    },

    setup: function() {
        this.collection.each(function(model) {
            this.bindings.add(model.tags(), "saved", _.bind(this.saveSuccess, this, model));
            this.bindings.add(model.tags(), "saveFailed", this.saveFailed);
            model.editableTags = model.tags().clone();
        }, this);
        this.tagBoxCollection = new chorus.views.TagBoxCollection({collection: this.collection});
    },

    saveTags: function() {
        if(!this.tagBoxCollection.finishLastTag()) { return; }

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
    }
});