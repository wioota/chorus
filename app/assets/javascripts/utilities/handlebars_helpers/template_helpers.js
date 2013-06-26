chorus.handlebarsHelpers.template = {
    renderTemplate: function(templateName, context) {
        return new Handlebars.SafeString(window.JST["templates/" + templateName](context));
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
    }
};

_.each(chorus.handlebarsHelpers.template, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});