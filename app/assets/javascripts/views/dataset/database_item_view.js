chorus.views.DatabaseItem = chorus.views.Base.extend({
    constructorName: "DatabaseItemView",
    templateName: "database_item",
    tagName: "li",

    additionalContext: function() {
        return {
            url: this.model.showUrl()
        };
    }
});
