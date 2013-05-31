chorus.dialogs.RenameWorkfile = chorus.dialogs.Base.extend({
    constructorName: "RenameWorkfileDialog",
    templateName: "rename_workfile_dialog",

    title: t("workfile.rename_dialog.title"),

    events: {
        "click button.submit": "submit"
    },

    submit: function(e) {
        e && e.preventDefault();
        this.model.set({fileName: this.$("input").val()});
        this.model.save();
    }
});