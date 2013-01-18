chorus.dialogs.ChangeWorkfileSchema = chorus.dialogs.Base.extend({
    constructorName: "ChangeWorkfileSchema",
    templateName: "change_workfile_schema",

    events: {
        "click button.submit": "save"
    },

    title:t("workfile.change_workfile_schema.title"),

    setup:function () {
        this.bindings.add(this.model, "saved", this.saved);
        this.bindings.add(this.model, "saveFailed", this.saveFailed);
    },

    save: function(e) {
        e.preventDefault();
        this.$("button.submit").startLoading("actions.saving");
        this.$("button.cancel").prop("disabled", true);
        this.model.saveWorkfileAttributes();
    },

    saved: function() {
        this.closeModal();
        chorus.toast("workfile.change_workfile_schema.saved_message");
    },

    saveFailed: function() {
        this.showErrors(this.model);
    }
});