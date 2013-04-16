chorus.dialogs.ImportScheduler = chorus.dialogs.ImportNow.extend({
    constructorName: "ImportSchedulerDialog",
    showSchedule: true,
    allowTruncate: true,

    subviews: {
        ".schedule": "scheduleView"
    },

    resourcesLoaded: function () {
        if (this.dataset.importSchedule()) {
            this.model.set(this.dataset.importSchedule());
        }
    },

    makeModel: function () {
        this.dataset = this.options.dataset;
        this.workspace = this.options.workspace;
        this.schema = this.workspace && this.workspace.sandbox().schema();
        this.model = new chorus.models.DatasetImportSchedule({
            datasetId: this.dataset.get("id"),
            workspaceId: this.dataset.get("workspace").id
        });
    },

    customSetup: function () {
        this.scheduleView = new chorus.views.ImportSchedule();
        this.registerSubView(this.scheduleView);

        var action = this.options.action;

        if(action === "create_schedule") {
            this.title = t("import.title_schedule");
            this.submitText = t("import.begin_schedule");
        } else {
            this.title = t("import.title_edit_schedule");
            this.submitText = t("actions.save_changes");
        }
    },

    postRender: function () {
        this.model && this.setFieldValuesFromSchedule(this.model);
        if(this.options.action === "create_schedule") {
            this.scheduleView.enable();
        }
        this.updateExistingTableLink();
    },

    setFieldValuesFromSchedule: function (schedule) {
        this._super("setFieldValuesFromSchedule", arguments);
        this.scheduleView.setFieldValues(schedule);
    },

    getNewModelAttrs: function () {
        var updates = this._super("getNewModelAttrs");
        _.extend(updates, this.scheduleView.fieldValues());
        return updates;
    },

    saveModel: function () {
        this.$("button.submit").startLoading("actions.saving");

        this.model.set({ workspaceId: this.workspace.get("id") });

        this.model.unset("sampleCount", {silent: true});
        try {
            this.model.save(this.getNewModelAttrs());
        } catch(e) {
            var message = e && e.message || "Invalid schedule";
            this.model.serverErrors = {fields: {date: {GENERIC: {message: message}}}};
            this.showErrors(this.model);
            this.$("button.submit").stopLoading();
        }
    },

    modelSaved: function () {
        chorus.toast("import.schedule.toast");
        chorus.PageEvents.trigger('importSchedule:changed', this.model);
        this.dataset.trigger('change');
        this.closeModal();
    }
});
