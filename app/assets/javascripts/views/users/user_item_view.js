chorus.views.UserItem = chorus.views.Base.extend(chorus.Mixins.TagsContext).extend({
    constructorName: "UserItemView",
    templateName: "user/user_item",
    tagName: "div",

    additionalContext: function() {
        return {
            admin: this.model.isAdmin(),
            iconUrl: this.model.fetchImageUrl({size: "icon"}),
            url: this.model.showUrl(),
            name: this.model.displayName(),
            title: this.model.get("title"),
            tags: this.model.tags().models
        };
    },

    postRender: function() {
        $(this.el).attr("data-userId", this.model.id);
    }
});
