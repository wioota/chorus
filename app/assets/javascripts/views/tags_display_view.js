chorus.views.TagsDisplay = chorus.views.Base.extend({
    templateName: "tags_display",
    constructorName: "TagsDisplayView",
    tags: [], // to make jshint happy

    setup: function() {
        this.tags = this.options.tags;
        this.taggable = this.options.taggable;
    },

    postRender: function() {
        this.buildTextExt();
    },
    
    buildTextExt: function() {
        var tagsForTextext = this.tags.map(function(tag) {
            return {name: tag.name(), model: tag};
        });

        this.$input.textext({
            plugins: 'tags ajax',
            tagsItems: tagsForTextext,
            itemManager: chorus.utilities.TagItemManager,
            ajax: {
                url: '/tags',
                dataType: 'json',
                existingTagCollection: this.tags
            }
        });
    },

    events: {

    },

    triggerTagClick: function(e, tag, value, callback) {
        this.trigger("tag:click", value.model);
    },

    resizeTextExt: function() {
        this.textext && this.textext.trigger('postInvalidate');
    },

    updateTags: function(e, tags) {
    },

    removeMissingTag: function(tags) {

    },

    textExtValidate: function(e, data) {
        this.invalidTagName = "";
        data.tag.name = $.trim(data.tag.name);
        data.tag.model = new chorus.models.Tag({name: data.tag.name});
        if(!this.validateTag(data.tag.model)) {
            data.result = false;

            if(this.keepInvalidTagName) {
                this.invalidTagName = data.tag.name;
                this.keepInvalidTagName = false;
            }
        }
    },

    validateTag: function(tag) {
        this.clearErrors();
        if(!tag.performValidation(tag.attributes)) {
            this.markInputAsInvalid(this.$input, tag.errors.name, false);
            this.keepInvalidTagName = true;
            return false;
        }
        return true;
    },

    restoreInvalidTag: function(e, tag) {
        this.$input.val(tag || this.invalidTagName);
        this.invalidTagName = "";
    },

    additionalContext: function() {
        return {
            tags: this.tags.models,
            hasTags: this.tags.length > 0
        };
    },

});
