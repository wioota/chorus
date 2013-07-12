chorus.dialogs.CreateHdfsDataset = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({

    constructorName: "CreateHdfsDatasetDialog",

    templateName: "create_hdfs_dataset",

    title: t("create_hdfs_dataset_dialog.title"),

    setup: function() {
        this.workspace = this.options.workspace;
        this.model = new chorus.models.HdfsDataset({ workspaceId: this.workspace.id });
        this.dataSources = new chorus.collections.HdfsDataSourceSet();
        this.dataSources.fetchAll();
        this.onceLoaded(this.dataSources, this.dataSourcesLoaded);

        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input",
            checkInput: _.bind(this.checkInput, this)
        });

        this.events["change select"] = this.toggleSubmitDisabled;

        this.listenTo(this.model, "saved", this.modelSaved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
    },

    checkInput: function() {
        return (this.$("input.name").val().trim().length > 0) &&
            (this.$("input.file_mask").val().trim().length > 0) &&
            this.$("select").val().trim();
    },

    additionalContext: function() {
        return {
            loaded: this.dataSources.loaded,
            dataSources: this.dataSources.models,
            dataSourcesPresent: this.dataSources.length > 0
        };
    },

    postRender: function() {
       this.$(".loading_spinner").startLoading();
       chorus.styleSelect(this.$(".data_source select"));
    },

    dataSourcesLoaded: function() {
        this.render();
    },

    create: function() {
        this.$("button.submit").startLoading();
        this.model.save(this.getFields());
    },

    modelSaved: function() {
        chorus.toast("create_hdfs_dataset_dialog.toast");
        this.closeModal();
    },

    getFields: function() {
        return {
            name: this.$("input.name").val(),
            dataSourceId: this.$(".data_source select").val(),
            fileMask: this.$("input.file_mask").val()
        };
    }
});