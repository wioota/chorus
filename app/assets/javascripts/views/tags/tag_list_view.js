chorus.views.TagList = chorus.views.Base.extend({
    constructorName: "TagListView",
    templateName:"tag_list",

    setup: function() {
        this.bindings.add(this.resource, 'loaded', this.render, this)
    }
});