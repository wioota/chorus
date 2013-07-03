chorus.dialogs.DataSourcesNew = chorus.dialogs.Base.extend({
    constructorName: "DataSourcesNew",
    templateName: "data_source_new",
    title: t("data_sources.new_dialog.title"),
    persistent: true,

    events: {
        "change select.data_sources": "showFieldset",
        "click a.close_errors": "clearServerErrors",
        "submit form": "createDataSource"
    },

    postRender: function() {
        _.defer(_.bind(function() {
            chorus.styleSelect(this.$("select.data_sources"), { format: function(text, option) {
                var aliasedName = $(option).val();
                    return '<span class='+ aliasedName +'></span>' + text;
            } });
            chorus.styleSelect(this.$("select.hdfs_version"), { format: function(text, option) {
                var aliasedName = $(option).attr("name");
                return '<span class='+ aliasedName +'></span>' + text;
            } });
        }, this));
    },

    makeModel: function () {
        this.model = this.model || new chorus.models.GpdbDataSource();
    },

    additionalContext: function() {
        var config = chorus.models.Config.instance();
        return {
            gnipConfigured:  config.get('gnipConfigured'),
            oracleConfigured:  config.get('oracleConfigured'),
            defaultGpdbFields: {dbName: "postgres"}
        };
    },

    showFieldset: function (e) {
        this.$(".data_sources_form").addClass("collapsed");
        var className = this.$("select.data_sources option:selected").attr("name");

        if(className.length) {
            this.$("." + className).removeClass("collapsed");
        }
        this.$("button.submit").prop("disabled", className === 'select_one');
        this.clearErrors();
    },

    createDataSource: function (e) {
        e && e.preventDefault();

        this.resource = this.model = new (this.dataSourceClass())();
        this.listenTo(this.model, "saved", this.saveSuccess);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.listenTo(this.model, "validationFailed", this.saveFailed);

        this.$("button.submit").startLoading("data_sources.new_dialog.saving");
        var values = this.fieldValues();
        this.model.save(values);
    },

    dataSourceClass: function() {
        var dataSourceType = this.$("select.data_sources option:selected").attr("name");
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
        var className = this.$("select.data_sources option:selected").attr("name");
        var inputSource = this.$("." + className);
        _.each(inputSource.find("input[type=text], input[type=hidden], input[type=password], textarea, select"), function (i) {
            var input = $(i);
            updates[input.attr("name")] = input.val().trim();
        });
        updates["isHawq"] = this.$("select.data_sources option:selected").attr("hawq");

        updates.shared = inputSource.find("input[name=shared]").prop("checked") ? "true" : "false";
        return updates;
    },

    clearServerErrors : function() {
        this.model.serverErrors = {};
    },

    saveSuccess: function () {
        chorus.PageEvents.trigger("data_source:added", this.model);
        chorus.toast('data_sources.add.toast', {dataSourceName: this.model.name()});
        this.closeModal();
    },

    saveFailed: function () {
        this.$("button.submit").stopLoading();
        this.showErrors();
    }
});

