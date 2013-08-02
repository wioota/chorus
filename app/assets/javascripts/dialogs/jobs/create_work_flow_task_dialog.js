chorus.dialogs.CreateWorkFlowTask = chorus.dialogs.PickItems.extend({
    constructorName: 'CreateWorkFlowTask',
    title: t('create_job_task_dialog.title'),
    searchPlaceholderKey: 'job_task.work_flow.search_placeholder',
    submitButtonTranslationKey: "create_job_task_dialog.submit",
    modelClass: "WorkFlow",
    pagination: true,
    multiSelection: false,

    setup: function() {
        this._super("setup");
        this.collection = this.options.collection;
        this.pickItemsList.templateName = "workfile_picker_list";
        this.pickItemsList.className = "workfile_picker_list";
        this.collection.fetch();
    },

    collectionModelContext: function (model) {
        return {
            id: model.get("id"),
            name: model.get("fileName"),
            imageUrl: model.iconUrl({size: 'icon'})
        };
    }
});