chorus.alerts.Analyze = chorus.alerts.Confirm.extend({
    constructorName: "Analyze",
    text: t("analyze.alert.text"),
    ok: t("analyze.alert.ok"),

    setup: function() {
        this.title = t("analyze.alert.title", {name: this.model.name()});
    },

    confirmAlert: function() {
        this.$("button.submit").startLoading("analyze.alert.loading");
        this.listenTo(this.model.analyze(), "saveFailed", this.saveFailed);
        this.listenTo(this.model.analyze(), "saved", this.saved);
        this.model.analyze().save();
    },

    saveFailed: function() {
        this.$("button.submit").stopLoading();
        this.showErrors(this.model.analyze());
    },

    saved: function() {
        chorus.PageEvents.trigger("analyze:running");
        chorus.toast("analyze.alert.toast", {name: this.model.name()});
        this.closeModal();
    }
});