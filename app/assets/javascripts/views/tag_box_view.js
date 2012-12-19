chorus.views.TagBox = chorus.views.Base.extend({
    templateName: "tag_box",
    constructorName: "TagBoxView",
    events: {
        "click .save_tags": "saveTags",
        "click .edit_tags": "editTags"
    },

    postRender: function() {
        var textarea = this.$('textarea.tag_editor');
        var tags = this.model.tags().map(function (tag) { return tag.attributes; });
        this.textext = textarea.textext({
            plugins: 'tags prompt focus autocomplete ajax arrow',
            tagsItems: tags,
            prompt: "",
            itemManager: chorus.utilities.TagItemManager,
            ajax: {
                url: '/taggings',
                dataType: 'json',
                cacheResults: false
            }
        });

        textarea.bind('isTagAllowed', _.bind(this.textExtValidate, this));
        textarea.bind('setInputData', _.bind(this.restoreInvalidTag, this));

        this.textext_elem = this.$('.text-core');
        if(!this.model.hasTags()) this.textext_elem.addClass("hidden");
        if(this.editing) {
            this.$el.addClass('editing')
        } else {
            this.$el.removeClass('editing')
        }
    },

    textExtValidate: function(e, data) {
        this.invalidTagName = "";
        if (!this.validateTag(data.tag.name)) {
            data.result = false;
            this.invalidTagName = data.tag.name;
        }
    },

    validateTag: function(tagName) {
        this.clearErrors();

        var valid = true;
        if(tagName.length > 100) {
            valid = false;
            this.markInputAsInvalid(this.$('textarea'), t("field_error.TOO_LONG", {field: "Tag", count : 100}), false);
        }

        var tags = JSON.parse(this.$('input[type=hidden]').val());
        if(_.any(tags, function(tag) { return tag.name === tagName })) {
            valid = false;
        }

        return valid;
    },

    restoreInvalidTag: function(e) {
        if (this.invalidTagName) {
            this.$('textarea').val(this.invalidTagName);
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
        var tags = JSON.parse(this.$('input[type=hidden]').val());
        var textareaText = this.$("textarea").val().trim();

        if(textareaText) {
            tags.push({name: textareaText});
            var tagsInvalid = !this.validateTag(textareaText)
        }

        if(!tagsInvalid) {
            this.model.tags().reset(tags, {silent: true});

            this.model.tags().save();

            this.editing = false;
            this.render();
        }
    },

    editTags: function(e){
        e.preventDefault();
        this.editing = true;
        this.render();
    }
});
