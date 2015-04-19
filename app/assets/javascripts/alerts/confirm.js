chorus.alerts.Confirm = chorus.alerts.Base.extend({
    constructorName: "ConfirmAlert",

    focusSelector: "button.submit",

    // class for the alert dialog style
    additionalClass: "info",
    
    postRender: function() {
        this._super('postRender');
        this.$("button.submit").removeClass('hidden');
    }
});