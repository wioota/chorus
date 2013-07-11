chorus.dialogs.EditHdfsDatasetDialog = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: "EditHdfsDatasetDialog",
    templateName: "edit_hdfs_dataset",
    title: t("edit_hdfs_dataset.title"),

    setup: function() {
        this.model = this.options.model;
        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input",
            checkInput: _.bind(this.checkInput, this)
        });

        this.listenTo(this.model, "saved", this.modelSaved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
    },

    checkInput: function() {
        return (this.$("input.name").val().trim().length > 0) &&
            (this.$("input.mask").val().trim().length > 0);
    },

    create: function() {
        this.$("button.submit").startLoading();
        this.model.save(this.getFields(), {silent: true});
    },

    getFields: function () {
        return {
            name: this.$("input.name").val(),
            datasetId: this.model.id,
            fileMask: this.$("input.mask").val()
        };
    },

    modelSaved: function() {
        chorus.toast("edit_hdfs_dataset.toast");
        this.closeModal();
    }
});