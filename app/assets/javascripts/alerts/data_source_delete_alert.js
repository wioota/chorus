chorus.alerts.DataSourceDelete = chorus.alerts.ModelDelete.extend({
    constructorName: "DataSourceDelete",

    text:t("data_sources.delete.text"),
    title:t("data_sources.delete.title"),
    ok:t("actions.delete"),
    deleteMessage:"data_sources.delete.toast",

    makeModel:function () {
        this.model = this.options.pageModel;
    }
});
