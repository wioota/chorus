chorus.views.WorkspaceItem = chorus.views.Base.extend({
    templateName: "workspace_item",
    tagName: "li",

    subviews: {
        ".summary": "summary"
    },

    additionalContext: function() {
        return {
            imageUrl: this.model.defaultIconUrl(),
            showUrl: this.model.showUrl(),
            ownerUrl: this.model.owner().showUrl(),
            archiverUrl: this.model.archiver().showUrl(),
            archiverFullName: this.model.archiver().displayName(),
            ownerFullName: this.model.owner().displayName(),
            active: this.model.isActive(),
            tags: this.model.tags().models
        };
    },

    summary: function() {
        return new chorus.views.TruncatedText({model: this.model, attribute: "summary", attributeIsHtmlSafe: true});
    },

    postRender: function() {
        $(this.el).attr("data-id", this.model.id);

        if(!this.model.isActive()) {
            $(this.el).addClass("archived");
        }
    }
});
