chorus.alerts.Error = chorus.alerts.Base.extend({
    constructorName: "Error",
    
    // default class for the alert:confirm dialog style
    additionalClass: "error",

    cancel: t("actions.close_window"),

    additionalContext: function() {
        return {
            closeOnEscape: false
        };
    },

    makeModel:function () {
        this._super("makeModel", arguments);
        this.options = this.options || {};
        this.body = this.options.body || this.model.serverErrorMessage();
        this.title = this.options.title || this.title;
    },

    postRender:function () {
        this._super("postRender");
        this.$(".errors").addClass('hidden');
    }
});
