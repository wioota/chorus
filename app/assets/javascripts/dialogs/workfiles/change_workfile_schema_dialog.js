chorus.dialogs.ChangeWorkfileSchema = chorus.dialogs.Base.extend({
    constructorName: "ChangeWorkfileSchema",
    templateName: "change_workfile_schema",

    events: {
        "click button.submit": "save"
    },

    subviews:{
        ".schema_picker":"schemaPicker"
    },

    title:t("workfile.change_workfile_schema.title"),

    setup:function () {
        this.bindings.add(this.model, "saved", this.saved);
        this.bindings.add(this.model, "saveFailed", this.saveFailed);

        var options = {};

        var schema = this.model.executionSchema();
        if (schema) {
            options.defaultSchema = schema;
        }

        this.schemaPicker = new chorus.views.SchemaPicker(options);
        this.bindings.add(this.schemaPicker, "change", this.enableOrDisableSubmitButton);
        this.bindings.add(this.schemaPicker, "error", this.showErrors);
        this.bindings.add(this.schemaPicker, "clearErrors", this.clearErrors);
    },

    postRender: function() {
        this._super("postRender");
        this.enableOrDisableSubmitButton();
    },

    save: function(e) {
        e.preventDefault();
        this.$("button.submit").startLoading("actions.saving");
        this.$("button.cancel").prop("disabled", true);
        this.model.updateExecutionSchema(this.schemaPicker.getSelectedSchema());
    },

    saved: function() {
        this.closeModal();
        chorus.toast("workfile.change_workfile_schema.saved_message");
    },

    saveFailed: function() {
        this.showErrors(this.model);
    },

    enableOrDisableSubmitButton:function () {
        this.$("button.submit").prop("disabled", !this.schemaPicker.ready());
    }
});