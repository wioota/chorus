chorus.views.WorkfileHeader = chorus.views.Base.extend({
    templateName: "workfile_header",
    constructorName: "WorkfileHeaderView",
    events: {
        "click .save_tags": "saveTags",
        "click .edit_tags": "editTags"
    },

    postRender: function() {
        var textarea = this.$('textarea');
        var tagNames = this.model.get("tagNames");
        this.textext = textarea.textext({
            plugins: 'tags prompt focus autocomplete',
            tagsItems: tagNames,
            prompt: ""
        });

        textarea.bind('isTagAllowed', _.bind(this.validateTag, this));
        textarea.bind('setInputData', _.bind(this.restoreInvalidTag, this));

        this.textext_elem = this.$('.text-core');
        if(!tagNames || !tagNames.length) this.textext_elem.addClass("hidden");
        this.$(".text-button").addClass("disabled");
    },

    validateTag: function(e, data) {
        this.clearErrors();
        this.invalidTag = "";
        if(data.tag.length > 100) {
            data.result = false;
            this.markInputAsInvalid(this.$('textarea'), t("field_error.TOO_LONG", {field: "Tag", count : 100}), false);
            this.invalidTag = data.tag;
        }
    },

    restoreInvalidTag: function(e) {
        if (this.invalidTag) {
            this.$('textarea').val(this.invalidTag);
            this.invalidTag = "";
        }
    },

    additionalContext: function() {
        return {
            iconUrl: this.model.iconUrl(),
            hasTags: (this.model.get("tagNames") && this.model.get("tagNames").length)
        };
    },


    saveTags: function(e) {
        e.preventDefault();
        var tagNames = JSON.parse(this.$('input[type=hidden]').val());

        this.model.set('tagNames', tagNames, {silent: true});

        $.post('/taggings', {
            entity_id: this.model.id,
            entity_type: 'workfile',
            tag_names: tagNames
        });

        this.$(".save_tags").toggleClass("hidden");
        this.$(".edit_tags").toggleClass("hidden");
        if(this.model.get("tagNames") && this.model.get("tagNames").length){}
        else {
            this.textext_elem.toggleClass("hidden");
        }
        this.$("textarea").prop("disabled","true");
        this.$("textarea").addClass("borderless");
        this.$(".text-button").addClass("disabled");
    },

    editTags: function(e){
        e.preventDefault();
        if(this.model.get("tagNames") && this.model.get("tagNames").length){}
        else {
            this.textext_elem.toggleClass("hidden");
        }
        this.$(".save_tags").toggleClass("hidden");
        this.$(".edit_tags").toggleClass("hidden");
        this.$("textarea").removeAttr("disabled");
        this.$("textarea").removeClass("borderless");
        this.$(".text-button").removeClass("disabled");
    }
});
