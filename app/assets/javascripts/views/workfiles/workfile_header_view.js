chorus.views.WorkfileHeader = chorus.views.Base.extend({
    templateName: "workfile_header",
    constructorName: "WorkfileHeaderView",
    events: {
//        "click .edit_tags": "openTagEditor",
        "click .save_tags": "saveTags"
    },

    postRender: function() {
        this.$('textarea').textext({
            plugins: 'tags prompt focus autocomplete',
            tagsItems: [],
            prompt: t('tags.prompt')
//            ajax: {
//                url: '/manual/examples/data.json',
//                dataType: 'json',
//                cacheResults: true
//            }
        });
    },

    additionalContext: function() {
        return {
            iconUrl: this.model.iconUrl()
        };
    },

    openTagEditor: function(e) {
//        e.preventDefault();
//        this.$('.edit_tag').remove();
//
//        $(this.el).append($("<textarea class='tag_editor'></textarea>"));
//        this.$('textarea').textext({
//            plugins: 'tags prompt focus autocomplete',
//            tagsItems: [],
//            prompt: t('tags.prompt'),
//            ajax: {
//                url: '/manual/examples/data.json',
//                dataType: 'json',
//                cacheResults: true
//            }
//        });
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
