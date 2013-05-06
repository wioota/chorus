chorus.alerts.DataSourceDelete = chorus.alerts.ModelDelete.extend({
    constructorName: "DataSourceDelete",

    title: t("data_sources.delete.title"),
    ok: t("actions.delete_data_source"),
    deleteMessage: "data_sources.delete.toast",

    deleteMessageParams: function() {
        return {
            dataSourceName: this.model.name()
        };
    },

    text: function() {
        return t("data_sources.delete.text." + this.model.get("entityType"));
    }
});
