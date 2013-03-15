chorus.views.WorkspaceMemberList = chorus.views.Base.extend({
    constructorName: "WorkspaceMemberList",
    templateName: "workspace_member_list",
    numberOfMembersToShow: 24,

    setup: function() {
        this.subscribePageEvent("workspace:selected", this.setWorkspace);
        if (this.options.collection) {
            this.setCollection(this.options.collection);
        }
    },

    additionalContext: function() {
        if (this.collection) {
            return {
                members: this.collection.chain().first(this.numberOfMembersToShow).map(
                    function(member) {
                        return {
                            imageUrl: member.fetchImageUrl({ size: 'icon' }),
                            showUrl: member.showUrl(),
                            displayName: member.displayName()
                        };
                    }).value(),
                extra_members: Math.max(this.collection.totalRecordCount() - this.numberOfMembersToShow, 0)
            };
        } else {
            return {};
        }
    },

    setCollection: function(collection) {
        this.setModel(collection);
        this.collection = collection;
        collection.fetchIfNotLoaded({per_page: this.numberOfMembersToShow});
    },

    setWorkspace: function(workspace) {
        if (workspace) {
            this.setCollection(workspace.members());
        }
        this.render();
    }
});
