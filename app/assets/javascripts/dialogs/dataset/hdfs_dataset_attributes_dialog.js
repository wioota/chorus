chorus.dialogs.HdfsDatasetAttributes = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: 'HdfsDatasetAttributes',
    templateName: "hdfs_dataset_attributes",

    setup: function () {
        this.model = this.findModel();

        this.loadDataSources();

        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input",
            checkInput: _.bind(this.checkInput, this)
        });

        this.events["change select"] = this.toggleSubmitDisabled;

        this.listenToModel();
    },

    listenToModel: function () {
        this.listenTo(this.model, "saved", this.modelSaved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
    },

    modelSaved: function () {
        chorus.toast(this.message);
        this.model.trigger('invalidated');
        this.closeModal();
    },

    getFields: function () {
        return {
            name: this.$("input.name").val(),
            dataSourceId: this.$(".data_source select").val(),
            datasetId: this.model.id,
            fileMask: this.$("input.file_mask").val()
        };
    },

    checkInput: function () {
        return (this.$("input.name").val().trim().length > 0) &&
            (this.$("input.file_mask").val().trim().length > 0) &&
            this.checkDataSource();
    },


    create: function () {
        this.$("button.submit").startLoading('actions.saving');
        this.model.save(this.getFields(), {wait: true});
    },

    loadDataSources: $.noop,

    checkDataSource: function () {
        return true;
    }

});