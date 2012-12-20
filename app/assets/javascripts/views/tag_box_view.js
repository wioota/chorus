chorus.views.TagBox = chorus.views.Base.extend({
    templateName: "tag_box",
    constructorName: "TagBoxView",
    events: {
        "click .save_tags": "saveTags",
        "click .edit_tags": "editTags"
    },

    postRender: function() {
        this.textarea = this.$('textarea.tag_editor');
        var tags = this.model.tags().map(function(tag) {
            return tag.attributes;
        });
        this.textarea.textext({
            plugins: 'tags focus autocomplete ajax',
            tagsItems: tags,
            itemManager: chorus.utilities.TagItemManager,
            ajax: {
                url: '/taggings',
                dataType: 'json',
                cacheResults: false
            },
            autocomplete: {
                dropdown: {
                    maxHeight: '200px'
                }
            }
        });

        this.textext = this.textarea.textext()[0];
        this.textarea.on("setFormData", _.bind(this.updateTags, this));
        this.textarea.bind('isTagAllowed', _.bind(this.textExtValidate, this));
        this.textarea.bind('setInputData', _.bind(this.restoreInvalidTag, this));

        this.textext_elem = this.$('.text-core');
        if(!this.model.hasTags()) this.textext_elem.addClass("hidden");
        if(this.editing) {
            this.$el.addClass('editing')
        } else {
            this.$el.removeClass('editing')
        }
    },

    updateTags: function(e, data) {
        this.model.tags().reset(data);
    },

    textExtValidate: function(e, data) {
        this.invalidTagName = "";
        if(!this.validateTag(data.tag.name)) {
            data.result = false;
            this.invalidTagName = data.tag.name;
        }
    },

    validateTag: function(tagName) {
        this.clearErrors();

        var valid = true;
        if(tagName.length > 100) {
            valid = false;
            this.markInputAsInvalid(this.textarea, t("field_error.TOO_LONG", {field: "Tag", count: 100}), false);
        }

        if (this.model.tags().containsTag(tagName)) {
            valid = false;
        }

        return valid;
    },

    restoreInvalidTag: function(e) {
        if(this.invalidTagName) {
            this.textarea.val(this.invalidTagName);
            this.invalidTagName = "";
        }
    },

    additionalContext: function() {
        return {
            hasTags: this.model.hasTags(),
            tags: this.model.tags().models
        };
    },

    saveTags: function(e) {
        e.preventDefault();

        var textareaText = this.textarea.val().trim();
        if(textareaText) {
            if(!this.validateTag(textareaText)) {
                return;
            }
            this.textext.tags().addTags([{name: textareaText}]);
        }

        this.model.tags().save();

        this.editing = false;
        this.render();
    },

    editTags: function(e) {
        e.preventDefault();
        this.editing = true;
        this.render();
    }
});
