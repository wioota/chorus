chorus.views.TagBox = chorus.views.Base.extend({
    templateName: "tag_box",
    constructorName: "TagBoxView",
    events: {
        "click .save_tags": "saveTags",
        "click .edit_tags": "editTags"
    },

    postRender: function() {
        this.input = this.$('input');
        var tags = this.model.tags().map(function(tag) {
            return tag.attributes;
        });
        this.input.textext({
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

        this.textext = this.input.textext()[0];
        this.input.on("setFormData", _.bind(this.updateTags, this));
        this.input.bind('isTagAllowed', _.bind(this.textExtValidate, this));
        this.input.bind('setInputData', _.bind(this.restoreInvalidTag, this));

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
            this.markInputAsInvalid(this.input, t("field_error.TOO_LONG", {field: "Tag", count: 100}), false);
        }

        if (this.model.tags().containsTag(tagName)) {
            valid = false;
        }

        return valid;
    },

    restoreInvalidTag: function(e) {
        if(this.invalidTagName) {
            this.input.val(this.invalidTagName);
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

        var inputText = this.input.val().trim();
        if(inputText) {
            if(!this.validateTag(inputText)) {
                return;
            }
            this.textext.tags().addTags([{name: inputText}]);
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
