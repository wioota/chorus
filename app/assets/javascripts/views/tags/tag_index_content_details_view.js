chorus.views.TagIndexContentDetails = chorus.views.Base.extend({
    constructorName: "TagIndexContentDetailsView",
    templateName:"tag_index_content_details",

    setup: function() {
        this.bindings.add(this.resource, 'loaded', this.render, this);
    }
});