chorus.views.TagListSidebar = chorus.views.Sidebar.extend({
    templateName: 'tag_list_sidebar',

    events: {
        "click .delete_tag_link" : "deleteSelectedTag"
    },

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
    },

    deleteSelectedTag: function(e) {
        e.preventDefault();
        this.deleteTagAlert = new chorus.alerts.TagDelete({ model: this.tag });
        this.deleteTagAlert.launchModal();
    }

});