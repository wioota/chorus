chorus.alerts.Base = chorus.Modal.extend({
    constructorName: "Alert",
    templateName: "alert_dialog",

    events: {
        "click button.cancel": "cancelAlert",
        "click button.submit": "confirmAlert"
    },

    confirmAlert: $.noop,

    focusSelector: "button.cancel",

    cancelAlert: function() {
        this.closeModal();
    },

    additionalContext: function(ctx) {
        return {
            title: this.title,
            text: _.result(this, 'text'),
            body: this.body,
            ok: this.ok,
            secondaryButton: this.secondaryButton,
            cancel: this.cancel || t("form.button.cancel")
        };
    },

    revealed: function() {
        $("#facebox").removeClass().addClass("alert_modal");
    }
});