chorus.dialogs.RenameWorkfile = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: "RenameWorkfileDialog",
    templateName: "rename_workfile_dialog",

    title: t("workfile.rename_dialog.title"),

    isSqlFile: function() {
        return this.model.get('fileType') === "sql";
    },

    additionalContext: function(){
        var isSql = this.isSqlFile();
        return {
            isSql: isSql,
            fileName: isSql ? this.model.get('fileName').replace(/\.sql$/,'') : this.model.get('fileName')
        };
    },

    setup: function() {
        this.listenTo(this.model, "saved", this.saved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input"
        });
    },

    create: function(e) {
        var fileName = this.$("input").val();
        this.model.save({fileName: this.isSqlFile() ? fileName + ".sql" : fileName }, {wait: true});
        this.$("button.submit").startLoading("actions.renaming");
    },

    saved: function() {
        this.closeModal();
        chorus.PageEvents.trigger('workfile:rename');
    }
});