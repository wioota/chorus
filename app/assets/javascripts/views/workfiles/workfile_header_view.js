chorus.views.WorkfileHeader = chorus.views.Base.extend({
    templateName: "workfile_header",
    constructorName: "WorkfileHeaderView",
    events: {
        "click .save_tags": "saveTags"
    },

    postRender: function() {
        this.$('textarea').textext({
            plugins: 'tags prompt focus autocomplete',
            tagsItems: [],
            prompt: t('tags.prompt')
        });
    },

    additionalContext: function() {
        return {
            iconUrl: this.model.iconUrl()
        };
    },


    saveTags: function(e) {
        e.preventDefault();
        var tagNames = JSON.parse(this.$('input[type=hidden]').val());

        $.post('/taggings', {
            entity_id: this.model.id,
            entity_type: 'workfile',
            tag_names: tagNames
        });
    }
});
