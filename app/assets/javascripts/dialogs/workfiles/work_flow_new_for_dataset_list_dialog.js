chorus.dialogs.WorkFlowNewForDatasetList = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    templateName: "work_flow_new",
    title: t("work_flows.new_dialog.title"),

    additionalContext: function () {
        return {
            userWillPickSchema: false
        };
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

        this.listenTo(this.resource, "saved", this.workfileSaved);
        this.listenTo(this.resource, "saveFailed", this.saveFailed);
    },

    getFileName: function() {
        return this.$("input[name=fileName]").val().trim();
    },

    checkInput: function() {
        return this.getFileName().trim().length > 0;
    },

    create: function(e) {
        var fileName = this.getFileName();
        this.resource.set({
            fileName: fileName,
            datasetIds: this.collection.pluck('id')
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
