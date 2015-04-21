chorus.dialogs.AssociateMultipleWithWorkspace = chorus.dialogs.PickWorkspace.extend({
    constructorName: "AssociateMultipleWithWorkspace",

    title: t("dataset.associate.title.other"),
    submitButtonTranslationKey: "dataset.associate.button.other",

    setup: function(options) {
        this.datasets = options.collection;
        this._super('setup', arguments);
    },

    submit: function() {
        this.$("button.submit").startLoading("actions.associating");

        var workspace = this.selectedItem();
        var datasetSet = workspace.datasets();
        datasetSet.reset(this.datasets.models);

        this.listenTo(datasetSet, "saved", this.saved);
        this.listenTo(datasetSet, "saveFailed", this.saveFailed);
        datasetSet.save();
    },

    saved: function() {
        this.datasets.each(function(dataset) { dataset.fetch(); });
        this.closeModal();
                
        var workspaceURL = this.selectedItem().showUrl();
        var workspaceName = this.selectedItem().get("name");
        var workspaceLink = Handlebars.helpers.linkTo (workspaceURL, workspaceName);
        chorus.toast("dataset.associate_multiple.toast", {
            count: this.datasets.length,
            workspaceNameTarget: workspaceLink,
            toastOpts: {type: "success"}
        });
    }
});
