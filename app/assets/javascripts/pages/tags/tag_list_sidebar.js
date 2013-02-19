chorus.views.TagListSidebar = chorus.views.Sidebar.extend({
    constructorName: 'TagListSidebar',
    templateName: 'tag_list_sidebar',

    events: {
        "click .delete_tag_link" : "deleteSelectedTag",
        "click .rename_tag_link" : "renameSelectedTag"
    },

    setup: function() {
        this.subscribePageEvent('tag:selected', function(tag) {
            this.setTag(tag);
        });
        this.subscribePageEvent('tag:deselected', function() {
            this.setTag(null);
        });
    },

    setTag: function(tag) {
      this.tag = tag;
      if(tag) {
          this.renameTagDialog = new chorus.dialogs.RenameTag({ model: tag });
          this.deleteTagAlert  = new chorus.alerts.TagDelete({ model: tag });
      }
      this.render();
    },

    additionalContext: function() {
        return {
            hasTag: this.tag !== null,
            name: this.tag && this.tag.get('name')
        };
    },

    deleteSelectedTag: function(e) {
        e.preventDefault();
        this.deleteTagAlert.launchModal();
    },

    renameSelectedTag: function(e) {
        e.preventDefault();
        this.renameTagDialog.launchModal();
    }
});