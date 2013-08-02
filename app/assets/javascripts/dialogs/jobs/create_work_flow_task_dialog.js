chorus.dialogs.CreateWorkFlowTask = chorus.dialogs.PickItems.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: 'CreateWorkFlowTask',
    title: t('create_job_task_dialog.title'),
    searchPlaceholderKey: 'job_task.work_flow.search_placeholder',
    submitButtonTranslationKey: "create_job_task_dialog.submit",
    modelClass: "WorkFlow",
    pagination: true,
    multiSelection: false,
    message: 'create_job_task_dialog.toast',


    setup: function() {
        this._super("setup");

        this.job = this.options.job;
        this.workspace = this.job.workspace();
        this.model = new chorus.models.JobTask({workspace: {id: this.workspace.get("id")}, job: {id: this.options.job.get("id")}});

        this.collection = this.options.collection;
        this.pickItemsList.templateName = "workfile_picker_list";
        this.pickItemsList.className = "workfile_picker_list";

        this.disableFormUnlessValid({
            formSelector: "form",
            checkInput: this.isWorkFlowSelected
        });

        this.listenTo(this.model, "saved", this.modelSaved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);

        this.collection.fetch();
    },

    collectionModelContext: function (model) {
        return {
            id: model.get("id"),
            name: model.get("fileName"),
            imageUrl: model.iconUrl({size: 'icon'})
        };
    },

    itemSelected: function (workFlow) {
        this.selectedWorkFlowId = workFlow.get("id");
        this.enableOrDisableSubmitButton();
    },

    isWorkFlowSelected: function () {
        return !!this.selectedWorkFlowId;
    },

    fieldValues: function () {
      return {
          workFlowId: this.selectedWorkFlowId,
          action: "run_work_flow"
      };
    },

    submit: function () {
        this.$('form').submit();
    },

    modelSaved: function () {
        chorus.toast(this.message);
        this.model.trigger('invalidated');
        this.job.trigger('invalidated');
        this.closeModal();
    },

    create: function () {
        this.$("button.submit").startLoading('actions.saving');
        this.model.save(this.fieldValues(), {wait: true});
    }
});