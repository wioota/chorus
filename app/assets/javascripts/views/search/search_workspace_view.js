chorus.views.SearchWorkspace = chorus.views.SearchItemBase.extend({
    constructorName: "SearchWorkspaceView",
    templateName: "search_workspace",

    additionalContext: function(){
        return {
            showUrl: this.model.showUrl(),
            iconUrl: this.model.defaultIconUrl(),
            tags: this.model.tags().models
        };
    }
});