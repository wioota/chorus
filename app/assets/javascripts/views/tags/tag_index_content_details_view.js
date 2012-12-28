chorus.views.TagIndexContentDetails = chorus.views.Base.extend({
    constructorName: "TagIndexContentDetailsView",
    templateName:"tag_index_content_details",

    setup: function() {
        this.bindings.add(this.options.tags, 'loaded', this.render, this);
    },

    additionalContext: function() {
        return {
            count: this.options.tags.models.length
        };
    }
});