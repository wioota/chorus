chorus.views.DatabaseItem = chorus.views.Base.extend({
    templateName: "database_item",
    tagName: "li",

    additionalContext: function() {
        return {
            showUrl: this.model.showUrl()
        };
    }
});
