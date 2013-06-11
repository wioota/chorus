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
    }
};

_.each(chorus.handlebarsHelpers.template, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});