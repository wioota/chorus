chorus.views.TagList = chorus.views.SelectableList.extend({
    constructorName: "TagListView",
    templateName:"tag_list",
    eventName: "tag",

    setup: function() {
        this.bindings.add(this.resource, 'loaded', this.render, this);
    }
});