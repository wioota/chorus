chorus.alerts.RemoveSharedAccount = chorus.alerts.Confirm.extend({
    constructorName: "RemoveSharedAccount",

    text:t("instances.remove_shared_account.text"),
    title:t("instances.remove_shared_account.title"),
    ok:t("instances.remove_shared_account.remove"),

    confirmAlert:function () {
        this.trigger("removeSharedAccount");
        this.closeModal();
    }
});

