chorus.alerts.AddSharedAccount = chorus.alerts.Confirm.extend({
    constructorName: "AddSharedAccount",
    text: t("instances.add_shared_account.text"),
    title: t("instances.add_shared_account.title"),
    ok: t("instances.add_shared_account.enable"),

    confirmAlert: function() {
        this.trigger("addSharedAccount");
        this.closeModal();
    }
});