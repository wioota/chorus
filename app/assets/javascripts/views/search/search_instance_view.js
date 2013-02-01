chorus.views.SearchInstance = chorus.views.SearchItemBase.extend({
    constructorName: "SearchInstanceView",
    templateName: "search_instance",

    setup: function() {
        this.additionalClass += " " + this.model.get("entityType");
    },

    additionalContext: function () {
        return {
            stateUrl: this.model.stateIconUrl(),
            stateText: this.model.stateText(),
            showUrl: this.model.showUrl(),
            humanSize: I18n.toHumanSize(this.model.get("size")),
            iconUrl: this.model.providerIconUrl()
        };
    }
});