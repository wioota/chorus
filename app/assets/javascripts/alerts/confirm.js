chorus.alerts.Confirm = chorus.alerts.Base.extend({
    constructorName: "ConfirmAlert",

    focusSelector: "button.submit",

    // default class for the alert:confirm dialog style
    additionalClass: "confirm",
    
    postRender: function() {
        this._super('postRender');
        this.$("button.submit").removeClass('hidden');
    }
});