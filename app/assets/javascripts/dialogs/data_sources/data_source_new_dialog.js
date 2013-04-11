chorus.dialogs.DataSourcesNew = chorus.dialogs.Base.extend({
    constructorName: "DataSourcesNew",
    templateName: "data_source_new",
    title: t("instances.new_dialog.title"),
    persistent: true,

    events: {
        "change select.data_sources": "showFieldset",
        "click button.submit": "createDataSource",
        "click a.close_errors": "clearServerErrors"
    },

    setup: function () {
        this.requiredResources.add(chorus.models.Config.instance());
    },

    postRender: function() {
        _.defer(_.bind(function() {
            chorus.styleSelect(this.$("select.data_sources"), { format: function(text, option) {
                var aliasedName = $(option).attr("name");
                    return '<span class='+ aliasedName +'></span>' + text;
            } });
        }, this));
    },

    makeModel: function () {
        this.model = this.model || new chorus.models.GpdbDataSource();
    },

    additionalContext: function() {
        return {
            gnipConfigured:  chorus.models.Config.instance().get('gnipConfigured'),
            oracleConfigured:  chorus.models.Config.instance().get('oracleConfigured')
        };
    },

    showFieldset: function (e) {
        this.$(".data_sources_form").addClass("collapsed");
        var className = $(e.currentTarget).val();

        if(className.length) {
            this.$("." + className).removeClass("collapsed");
        }
        this.$("button.submit").prop("disabled", className.length === 0);
        this.clearErrors();
    },

    createDataSource: function (e) {
        e && e.preventDefault();

        this.resource = this.model = new (this.dataSourceClass())();
        this.listenTo(this.model, "saved", this.saveSuccess);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.listenTo(this.model, "validationFailed", this.saveFailed);

        this.$("button.submit").startLoading("instances.new_dialog.saving");
        var values = this.fieldValues();
        this.model.set(values);
        this.model.save();
    },

    dataSourceClass: function() {
        var dataSourceType = this.$("select.data_sources").val();
        if (dataSourceType === "register_existing_hdfs") {
            return chorus.models.HdfsDataSource;
        } else if (dataSourceType === "register_existing_gnip") {
            return chorus.models.GnipDataSource;
        } else if (dataSourceType === "register_existing_oracle") {
            return chorus.models.OracleDataSource;
        } else {
            return chorus.models.GpdbDataSource;
        }
    },

    fieldValues: function() {
        var updates = {};
        var className = this.$("select.data_sources").val();
        var inputSource = this.$("." + className);
        _.each(inputSource.find("input[type=text], input[type=hidden], input[type=password], textarea, select"), function (i) {
            var input = $(i);
            updates[input.attr("name")] = input.val().trim();
        });

        updates.shared = inputSource.find("input[name=shared]").prop("checked") ? "true" : "false";
        return updates;
    },

    clearServerErrors : function() {
        this.model.serverErrors = {};
    },

    saveSuccess: function () {
        chorus.PageEvents.broadcast("data_source:added", this.model);
        chorus.toast('instances.add.toast', {dataSourceName: this.model.name()});
        this.closeModal();
    },

    saveFailed: function () {
        this.$("button.submit").stopLoading();
        this.showErrors();
    }
});

