chorus.dialogs.DataSourceEdit = chorus.dialogs.Base.extend({
    constructorName: "DataSourceEdit",

    templateName: "data_source_edit",
    title: t("instances.edit_dialog.title"),
    events: {
        "submit form": "save"
    },

    makeModel: function() {
        this.sourceModel = this.options.instance;
        this.model = new chorus.models[this.sourceModel.constructorName](this.sourceModel.attributes);
    },

    setup: function() {
        this.listenTo(this.model, "saved", this.saveSuccess);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.listenTo(this.model, "validationFailed", this.saveFailed);
    },

    additionalContext: function() {
        return {
            gpdbOrOracleDataSource: this.model.get("entityType") === "gpdb_data_source" || this.model.get("entityType") === "oracle_data_source",
            hdfsDataSource: this.model.constructorName === "HdfsDataSource",
            gnipDataSource: this.model.constructorName === "GnipDataSource"
        };
    },

    save: function(e) {
        e.preventDefault();
        var attrs = {
            description: this.$("textarea[name=description]").val().trim()
        };

        _.each(["name", "host", "port", "size", "dbName", "username", "groupList", "streamUrl", "password"], function(name) {
            var input = this.$("input[name=" + name + "]");
            if (input.length) {
                attrs[name] = input.val().trim();
            }
        }, this);

        this.$("button.submit").startLoading("instances.edit_dialog.saving");
        this.$("button.cancel").prop("disabled", true);
        this.model.save(attrs, {silent: true});
    },

    saveSuccess: function() {
        this.sourceModel.set(this.model.attributes);
        chorus.toast("instances.edit_dialog.saved_message");
        this.closeModal();
    },

    saveFailed: function() {
        this.$("button.submit").stopLoading();
        this.$("button.cancel").prop("disabled", false);
    }
});
