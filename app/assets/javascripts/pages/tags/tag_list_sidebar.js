chorus.views.TagListSidebar = chorus.views.Sidebar.extend({
    constructorName: 'TagListSidebar',
    templateName: 'tag_list_sidebar',

    events: {
        "click .delete_tag_link" : "deleteSelectedTag"
    },

    setup: function() {
        this.subscribePageEvent('tag:selected', function(tag) {
            this.tag = tag;
            this.render();
        });
        this.subscribePageEvent('tag:deselected', function() {
            this.tag = null;
            this.render();
        });
    },

    additionalContext: function() {
        return {
            hasTag: this.tag !== null,
            name: this.tag && this.tag.get('name')
        };
    },

    deleteSelectedTag: function(e) {
        e.preventDefault();
        this.deleteTagAlert = new chorus.alerts.TagDelete({ model: this.tag });
        this.deleteTagAlert.launchModal();
    }

});