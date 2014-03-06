chorus.handlebarsHelpers.template = {
    renderTemplate: function(templateName, context) {
        return new Handlebars.SafeString(window.HandlebarsTemplates[templateName](context));
    },

    formControls:function(submitText, cancelText) {
        if(cancelText && cancelText.hash) {
            cancelText = "actions.cancel";
        }
        return Handlebars.helpers.renderTemplate("components/form_controls", { submitText: submitText, cancelText: cancelText});
    },

    formControlsWithDisabledSubmit: function(submitText, cancelText) {
        if(cancelText && cancelText.hash) {
            cancelText = "actions.cancel";
        }
        return Handlebars.helpers.renderTemplate("components/form_controls", { submitText: submitText, cancelText: cancelText, disabled: true});
    },

    infoBlock: function(infoTranslation) {
        return Handlebars.helpers.renderTemplate("components/info_block", {info: infoTranslation});
    },

    renderTemplateIf: function(conditional, templateName, context) {
        if (conditional) {
            return Handlebars.helpers.renderTemplate(templateName, context);
        } else {
            return "";
        }
    },

    renderErrors: function(serverErrors) {
        var output = ["<ul>"];
        var errorMessages = chorus.Mixins.ServerErrors.serverErrorMessages.call({serverErrors: serverErrors});

        _.each(errorMessages, function(message) {
            output.push("<li>" + Handlebars.Utils.escapeExpression(message) + "</li>");
        });

        output.push("</ul>");
        return new Handlebars.SafeString(output.join(""));
    },

    spanFor: function(text, attributes) {
        return new Handlebars.SafeString($("<span></span>").text(text).attr(attributes || {}).outerHtml());
    },

    uploadWidgetFor: function(propertyName) {
        return Handlebars.helpers.renderTemplate("components/upload_widget", { propertyName: propertyName });
    },

    hdfsDataSourceFields: function(context) {
        return Handlebars.helpers.renderTemplate("data_sources/hdfs_data_source_fields", context || {});
    },

    hdfsVersionsSelect: function(selectOne) {
        selectOne = selectOne === undefined ? true : selectOne;
        return Handlebars.helpers.renderTemplate("data_sources/hdfs_versions_select", {
            hdfsVersions: chorus.models.Config.instance().get("hdfsVersions"),
            selectOne: selectOne
        });
    },

    timeZonesSelect: function () {
        return Handlebars.helpers.renderTemplate('time_zone_selector', {
            zones: chorus.models.Config.instance().get("timeZones")
        });
    },

    gpdbOrOracleDataSourceFields: function(context) {
        return Handlebars.helpers.renderTemplate("data_sources/gpdb_or_oracle_data_source_fields", context || {});
    },

    jdbcDataSourceFields: function(context) {
        return Handlebars.helpers.renderTemplate("data_sources/jdbc_data_source_fields", context || {});
    },

    workflowResultLink: function (jobTaskResult) {
        var result = new chorus.models.WorkFlowResult({workfileId: jobTaskResult.payloadId, id: jobTaskResult.payloadResultId});
        return Handlebars.helpers.renderTemplate("workflow_result_link", { link: result.showUrl(), name: result.name() });
    },

    modelNamesList: function(collection) {
        function name(m) { return _.result(m, "name"); }
        function appendLast(model) { return ", and " + name(model); }

        var list = "";
        var comma = ", ";
        var last;
        var c = collection.clone();
        var length = c.length;

        switch (length) {
            case 0:
                list = "";
                break;
            case 1:
                list = name(c.pop());
                break;
            case 2:
                list = c.map(name).join(" and ");
                break;
            case 3:
                last = c.pop();
                list = c.map(name).join(comma) + appendLast(last);
                break;
            default:
                list = c.slice(0,2).map(name).join(comma) + appendLast({name: length - 2 + " others"});
                break;
        }

        return new Handlebars.SafeString(list);
    }
};

_.each(chorus.handlebarsHelpers.template, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});
