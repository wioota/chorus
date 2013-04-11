chorus.dialogs.SchemaPicker = chorus.dialogs.Base.extend({
    templateName: "schema_picker_dialog",
    constructorName: "SchemaPicker",

    events: {
        "click button.submit": "save"
    },

    subviews:{
        ".schema_picker":"schemaPicker"
    },

    schemaPickerTranslation: function(key) {
        return t(["schema_picker", this.options.action, key].join("."));
    },

    setup: function() {
        this.title = this.schemaPickerTranslation("title");

        this.schemaPicker = new chorus.views.SchemaPicker({ defaultSchema: this.options.schema });
        this.listenTo(this.schemaPicker, "change", this.enableOrDisableSubmitButton);
        this.listenTo(this.schemaPicker, "error", this.showErrors);
        this.listenTo(this.schemaPicker, "clearErrors", this.clearErrors);
    },

    additionalContext: function() {
        return {
            save: this.schemaPickerTranslation("save")
        };
    },

    enableOrDisableSubmitButton:function () {
        this.$("button.submit").prop("disabled", !this.schemaPicker.ready());
    },

    save: function() {
        this.trigger("schema:selected", this.schemaPicker.getSelectedSchema());
        this.closeModal();
    }
});
