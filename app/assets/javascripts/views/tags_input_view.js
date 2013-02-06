chorus.views.TagsInput = chorus.views.Base.extend({
    templateName: "tags_input",
    constructorName: "TagsInputView",
    tags: [], // to make jshint happy

    setup: function() {
        this.tags = this.options.tags;
    },

    postRender: function() {
        this.input = this.$('input');
        this.tagsForTextext = this.tags.map(function(tag) {
            return {name: tag.name(), model: tag};
        });

        var textextInput = this.input.textext({
            plugins: 'tags autocomplete ajax',
            tagsItems: this.tagsForTextext,
            itemManager: chorus.utilities.TagItemManager,
            keys: {
                8   : 'backspace',
                9   : 'tab',
                13  : 'enter!',
                27  : 'escape',
                37  : 'left',
                38  : 'up!',
                39  : 'right',
                40  : 'down!',
                46  : 'delete',
                108 : 'numpadEnter'
            },
            ajax: {
                url: '/tags',
                dataType: 'json',
                existingTagCollection: this.tags
            },
            autocomplete: {
                render: function(suggestion) {
                    return Handlebars.Utils.escapeExpression(suggestion.suggestionText || suggestion.name);
                },
                dropdown: {
                    maxHeight: '200px'
                }
            }
        });

        this.input.attr("placeholder", t("tags.add_tags"));

        // TODO #42333697: change these to use this.binding.add so they get cleaned up
        this.textext = this.input.textext()[0];
        this.input.on("setFormData", _.bind(this.updateTags, this));
        this.input.bind('isTagAllowed', _.bind(this.textExtValidate, this));
        this.input.bind('setInputData', _.bind(this.restoreInvalidTag, this));
        // this is so the dropdown always appears at the bottom of the text area
        this.input.bind('focus', _.bind(this.resizeTextExt, this));
        textextInput.bind('tagClick', _.bind(function(e, tag, value, callback) {
            this.trigger("tag:click", value.model);
        }, this));
    },

    resizeTextExt: function() {
        this.textext.trigger('postInvalidate');
    },

    updateTags: function(e, tags) {
        if(tags.length > this.tags.length) {
            this.addTag(_.last(tags));
        } else if(tags.length < this.tags.length) {
            this.removeMissingTag(tags);
        }
    },

    addTag: function(newTag) {
        var duplicate = this.tags.find(function(tag) {
            return tag.matches(newTag.name);
        });
        if(duplicate) {
            this.tags.remove(duplicate, {silent: true});
        }
        this.tags.add(newTag);
        this.render();
        this.focusInput();
    },

    removeMissingTag: function(tags) {
        var tagNames = _.pluck(tags, "name");
        var missingTag = this.tags.find(function(tag) {
            return !_.contains(tagNames, tag.name());
        });
        this.tags.remove(missingTag);
    },

    textExtValidate: function(e, data) {
        this.invalidTagName = "";
        data.tag.name = $.trim(data.tag.name);
        if(!this.validateTag(data.tag.name)) {
            data.result = false;

            if(this.keepInvalidTagName) {
                this.invalidTagName = data.tag.name;
                this.keepInvalidTagName = false;
            }
        }
    },

    validateTag: function(tagName) {
        this.clearErrors();

        tagName = tagName.trim();

        var valid = true;
        if(tagName.length > 100) {
            valid = false;
            this.keepInvalidTagName = true;
            this.markInputAsInvalid(this.input, t("field_error.TOO_LONG", {field: "Tag", count: 100}), false);
        } else if(tagName.indexOf("~") !== -1) {
            valid = false;
            this.keepInvalidTagName = true;
            this.markInputAsInvalid(this.input, t("field_error.INVALID_CHARACTER", {field: "Tag", character: "~"}), false);
        } else if(tagName.length === 0) {
            valid = false;
        }

        return valid;
    },

    restoreInvalidTag: function(e, tag) {
        this.input.val(tag || this.invalidTagName);
        this.invalidTagName = "";
    },

    additionalContext: function() {
        return {
            tags: this.tags.models,
            hasTags: this.tags.length > 0
        };
    },

    focusInput: function() {
        this.input.focus();
    }
});
