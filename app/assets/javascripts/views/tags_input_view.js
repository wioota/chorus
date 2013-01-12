chorus.views.TagsInput = chorus.views.Base.extend({
    templateName: "tags_input",
    constructorName: "TagsInputView",
    tags: [], // to make jshint happy

    setup: function() {
        this.tags = this.options.tags;
    },

    postRender: function() {
        this.input = this.$('input');
        var tagsForTextext = this.tags.map(function(tag) {
            return tag.attributes;
        });
        this.input.textext({
            plugins: 'tags autocomplete ajax',
            tagsItems: tagsForTextext,
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
                    return Handlebars.Utils.escapeExpression(suggestion.name);
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
    },

    resizeTextExt: function() {
        this.textext.trigger('postInvalidate');
    },

    updateTags: function(e, data) {
        if(data.length > this.tags.length) {
            // add
            var added = _.last(data);
            this.tags.add(added);
        } else if(data.length < this.tags.length) {
            // remove
            var tagNames = _.pluck(data, "name");
            var missingTag = this.tags.find(function(tag) {
                return !_.contains(tagNames, tag.name());
            });
            this.tags.remove(missingTag);
        }
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
        } else if (tagName.length === 0) {
            valid = false;
        }

        if (this.tags.containsTag(tagName)) {
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
            tags: this.tags.models,
            hasTags: this.tags.length > 0
        };
    },

    focusInput: function() {
        this.input.focus();
    }
});
