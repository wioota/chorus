chorus.views.TagListSidebar = chorus.views.Sidebar.extend({
    templateName: 'tag_list_sidebar',

    setup: function() {
        chorus.PageEvents.subscribe('tag:selected', function(tag) {
            this.tag = tag;
            this.render();
        }, this);
    },

    additionalContext: function() {
        return {
            name: this.tag && this.tag.get('name')
        };
    }
});