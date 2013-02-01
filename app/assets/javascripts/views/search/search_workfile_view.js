chorus.views.SearchWorkfile = chorus.views.SearchItemBase.extend({
    constructorName: "SearchWorkfileView",
    templateName: "search_workfile",

    additionalContext: function () {
        return {
            showUrl: this.model.showUrl(),
            iconUrl: this.model.iconUrl(),
            workspaces: [this.model.workspace().attributes],
            tags: this.model.tags().models
        };
    },

    makeCommentList: function (){
        var comments = this.model.get("comments") || [];
        var commitMessages = this.model.get("highlightedAttributes") && this.model.get("highlightedAttributes").commitMessage;
        _.each(commitMessages || [], function(commitMessage) {
            comments.push({isCommitMessage:true, body: new Handlebars.SafeString(commitMessage)});
        }, this);

        return new chorus.views.SearchResultCommentList({comments: comments});
    }
});