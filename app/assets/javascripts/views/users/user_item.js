chorus.views.UserItem = chorus.views.Base.extend(chorus.Mixins.TagsContext).extend({
    templateName: "user/user_item",
    tagName: "li",

    additionalContext: function() {
        return {
            admin: this.model.isAdmin(),
            imageUrl: this.model.fetchImageUrl({size: "icon"}),
            showUrl: this.model.showUrl(),
            fullName: this.model.displayName(),
            title: this.model.get("title"),
            tags: this.model.tags().models
        };
    },

    postRender: function() {
        $(this.el).attr("data-userId", this.model.id);
    }
});
