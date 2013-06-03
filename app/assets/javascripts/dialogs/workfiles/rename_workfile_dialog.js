chorus.dialogs.RenameWorkfile = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: "RenameWorkfileDialog",
    templateName: "rename_workfile_dialog",

    title: t("workfile.rename_dialog.title"),

    setup: function() {
        this.listenTo(this.model, "saved", this.saved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input"
        });
    },

    create: function(e) {
        this.model.set({fileName: this.$("input").val()}, {silent: true});
        this.model.save();
        this.$("button.submit").startLoading("actions.renaming");
    },

    saved: function() {
        this.closeModal();
    },

    saveFailed: function() {
        this.$("button.submit").stopLoading();
    }
});