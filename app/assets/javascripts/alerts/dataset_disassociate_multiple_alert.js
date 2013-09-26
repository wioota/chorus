chorus.alerts.DatasetDisassociateMultiple = chorus.alerts.ModelDelete.extend({
    constructorName: "DatasetDisassociateMultiple",

    setup: function() {
        this._super("setup");

        this.text = t("dataset_delete.many.text");
        this.title = t("dataset_delete.many.title");
        this.ok = t("dataset_delete.many.button");
        this.deleteMessage = "dataset_delete.many.toast";
        this.redirectUrl = this.model.showUrl();
    },

    deleteMessageParams:function () {
        return {
            count: this.model.length
        };
    }
});

