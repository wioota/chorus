chorus.dialogs.ImportScheduler = chorus.dialogs.ImportNow.extend({
    constructorName: "ImportSchedulerDialog",
    showSchedule: true,
    allowTruncate: true,

    subviews: {
        ".new_table .schedule": "scheduleViewNew",
        ".existing_table .schedule": "scheduleViewExisting"
    },

    resourcesLoaded: function () {
        this.model = this.schedule = this.dataset.importSchedule() || this.model;
        this._super('resourcesLoaded');
    },

    makeModel: function () {
        this.dataset = this.options.dataset;
        this.workspace = this.options.workspace;
        this.model = new chorus.models.DatasetImportSchedule({
            datasetId: this.dataset.get("id"),
            workspaceId: this.dataset.get("workspace").id
        });
    },

    customSetup: function () {
        this.scheduleViewNew = new chorus.views.ImportSchedule();
        this.registerSubView(this.scheduleViewNew);
        this.scheduleViewExisting = new chorus.views.ImportSchedule();
        this.registerSubView(this.scheduleViewExisting);

        var action = this.options.action;

        if(action === "create_schedule") {
            this.title = t("import.title_schedule");
            this.submitText = t("import.begin_schedule");
        } else {
            this.title = t("import.title_edit_schedule");
            this.submitText = t("actions.save_changes");
        }

        this.activeScheduleView = this.scheduleViewNew;
    },

    postRender: function () {
        this.schedule && this.setFieldValues(this.schedule);
        if(this.options.action === "create_schedule") {
            this.activeScheduleView.enable();
        }
        this.updateExistingTableLink();
    },

    updateExistingTableLink: function () {
        this._super("updateExistingTableLink");
        var disableExisting = this.$(".new_table input:radio").prop("checked");

        this.activeScheduleView = disableExisting ? this.scheduleViewNew : this.scheduleViewExisting;
        if(this.options.action === "create_schedule") {
            this.activeScheduleView.enable();
        }
    },

    setFieldValues: function (model) {
        this._super("setFieldValues", arguments);
        var newTable = model.get("newTable") === true;
        this.activeScheduleView = newTable ? this.scheduleViewNew : this.scheduleViewExisting;

        this.scheduleViewExisting.setFieldValues(model);
        this.scheduleViewNew.setFieldValues(model);
    },

    getNewModelAttrs: function () {
        var updates = this._super("getNewModelAttrs");
        _.extend(updates, this.activeScheduleView.fieldValues());
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
        chorus.PageEvents.broadcast('importSchedule:changed', this.model);
        this.dataset.trigger('change');
        this.closeModal();
    }
});
