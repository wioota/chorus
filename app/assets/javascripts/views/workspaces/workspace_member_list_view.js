chorus.views.WorkspaceMemberList = chorus.views.Base.extend({
    constructorName: "WorkspaceMemberList",
    templateName: "workspace_member_list",
    numMembers: 24,

    setup: function() {
        this.subscribePageEvent("workspace:selected", this.setWorkspace);
    },

    context: function() {
        if (this.model) {
            return {
                members: this.model.members().chain().first(this.numMembers).map(
                    function(member) {
                        return {
                            imageUrl: member.fetchImageUrl({ size: 'icon' }),
                            showUrl: member.showUrl(),
                            displayName: member.displayName()
                        };
                    }).value(),
                extra_members: Math.max(this.model.members().totalRecordCount() - this.numMembers, 0)
            };
        } else {
            return {};
        }
    },

    setWorkspace: function(workspace) {
        this.resource = this.model = workspace;
        if (workspace) {
            workspace.members().fetchAllIfNotLoaded();
            this.bindings.add(workspace.members(), "loaded", this.render);
        }
        this.render();
    }
});
