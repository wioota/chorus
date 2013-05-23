chorus.dialogs.WorkFlowNew = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    templateName: "work_flow_new",
    title: t("work_flows.new_dialog.title"),
    persistent: true,

    subviews: {
        ".database_picker": "schemaPicker"
    },

    setup: function() {
        this.model = this.resource = new chorus.models.AlpineWorkfile({
            workspace: {id: this.options.workspace.id }
        });
        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input[name=fileName]",
            checkInput: _.bind(this.checkInput, this)
        });

        this.schemaPicker = new chorus.views.SchemaPicker({
            showSchemaSection: false,
            defaultSchema: this.options.workspace.sandbox()
        });
        this.listenTo(this.schemaPicker, "change", this.toggleSubmitDisabled);
        this.listenTo(this.resource, "saved", this.workfileSaved);
        this.listenTo(this.resource, "saveFailed", this.saveFailed);
    },

    getFileName: function() {
        return this.$("input[name=fileName]").val().trim();
    },

    checkInput: function() {
        return this.getFileName().trim().length > 0 && !!this.schemaPicker.ready();
    },

    create: function(e) {
        var fileName = this.getFileName();

        this.resource.set({
            fileName: fileName,
            databaseId: this.schemaPicker.getSelectedDatabase().id
        });

        this.$("button.submit").startLoading("actions.adding");
        this.resource.save();
    },

    saveFailed: function() {
        this.$("button.submit").stopLoading();
    },

    workfileSaved: function() {
        this.closeModal();
        chorus.router.navigate(this.resource.showUrl({workFlow: true}));
    }
});
