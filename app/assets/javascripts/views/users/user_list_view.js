chorus.views.UserList = chorus.views.CheckableList.extend({
    templateName: "user/list",
    eventName: "user",

    collectionModelContext: function(model) {
        return {
            imageUrl: model.fetchImageUrl({size: "icon"}),
            showUrl: model.showUrl(),
            fullName: model.displayName(),
            title: model.get("title"),
            tags: model.tags().models
        };
    },

    postRender: function() {
        chorus.views.SelectableList.prototype.postRender.apply(this);

        this.checkSelectedModels();
    }
});
