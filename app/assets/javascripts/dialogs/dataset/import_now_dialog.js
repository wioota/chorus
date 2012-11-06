chorus.dialogs.ImportNow = chorus.dialogs.Base.extend({
    constructorName: "ImportNowDialog",
    templateName: "import_scheduler",

    useLoadingSection: true,
    persistent: true,

    showSchedule: false,

    subviews: {
        ".new_table .schedule": "scheduleViewNew",
        ".existing_table .schedule": "scheduleViewExisting"
    },

    events: {
        "change input:radio": "onDestinationChosen",
        "change input:checkbox": "onCheckboxClicked",
        "keyup input:text": "onInputFieldChanged",
        "paste input:text": "onInputFieldChanged",
        "cut input:text": "onInputFieldChanged",
        "click button.submit": "beginImport",
        "click button.cancel": "onClickCancel",
        "click .existing_table a.dataset_picked": "launchDatasetPickerDialog"
    },

    resourcesLoaded: function() {
        this.schedule = this.dataset.importSchedule();
        this.bindings.add(this.model, "saved", this.importSaved);
        this.bindings.add(this.model, "saveFailed validationFailed", function() {
            this.$("button.submit").stopLoading();
        });
    },

    makeModel: function() {
        this.dataset = this.options.dataset;
        this.workspace = this.options.workspace;
        this.model = new chorus.models.DatasetImport({
            datasetId: this.dataset.get("id"),
            workspaceId: this.dataset.get("workspace").id
        });
    },

    setup: function() {
        this.importSchedules = this.dataset.getImportSchedules();
        this.importSchedules.fetchIfNotLoaded();
        this.requiredResources.push(this.importSchedules);

        this.scheduleViewNew = new chorus.views.ImportSchedule();
        this.registerSubView(this.scheduleViewNew);
        this.scheduleViewExisting = new chorus.views.ImportSchedule();
        this.registerSubView(this.scheduleViewExisting);

        var action = this.options.action;

        if (action === "create_schedule") {
            this.title = t("import.title_schedule");
            this.submitText = t("import.begin_schedule");
            this.activeScheduleView = this.scheduleViewNew;
        } else if (action === "edit_schedule") {
            this.title = t("import.title_edit_schedule");
            this.submitText = t("actions.save_changes");
            this.activeScheduleView = this.scheduleViewNew;
        } else {
            this.title = t("import.title");
            this.submitText = t("import.begin");
        }
    },

    postRender: function() {
        this.schedule && this.setFieldValues(this.schedule);
        if (this.options.action === "create_schedule") {
            this.activeScheduleView.enable();
        }
        this.updateExistingTableLink();
    },

    launchDatasetPickerDialog: function(e) {
        e.preventDefault();
        if (!this.saving) {
            var datasetDialog = new chorus.dialogs.DatasetsPicker({
                workspaceId: this.workspace.get('id'),
                defaultSelection: this.schedule && this.schedule.destination()
            });
            this.bindings.add(datasetDialog, "datasets:selected", this.datasetsChosen, this);
            this.launchSubModal(datasetDialog);
        }
    },

    datasetsChosen: function(datasets){
        this.changeSelectedDataset(datasets && datasets[0] && datasets[0].name());
    },

    changeSelectedDataset: function(name) {
        if(name) {
            this.$(".existing_table a.dataset_picked").text(_.prune(name, 20));
            this.$(".existing_table a.dataset_picked").data("dataset", name);
            this.$(".existing_table span.dataset_picked").text(_.prune(name, 20));
            this.onInputFieldChanged();
        }
    },

    toggleExistingTableLink: function(asLink) {
        var $a = this.$(".existing_table a.dataset_picked");
        var $span = this.$(".existing_table span.dataset_picked");
        if (asLink) {
            $a.removeClass("hidden");
            $span.addClass("hidden");
        } else {
            $a.addClass("hidden");
            $span.removeClass("hidden");
        }
    },

    setFieldValues: function(model) {
        this.$("input[type='radio']").prop("checked", false);
        var newTable = model.get("newTable");
        if (!newTable) {
            this.$("input[type='radio']#import_scheduler_existing_table").prop("checked", true).change();
            this.activeScheduleView = this.scheduleViewExisting;
            this.changeSelectedDataset(model.get("toTable"));
        } else {
            this.activeScheduleView = this.scheduleViewNew;
            this.$(".new_table input.name").val(model.get("toTable"));
            this.$("input[type='radio']#import_scheduler_new_table").prop("checked", true).change();
        }
        this.scheduleViewExisting.setFieldValues(model);
        this.scheduleViewNew.setFieldValues(model);
        if (model.get("truncate")) {
            this.$(".truncate").prop("checked", true);
        } else {
            this.$(".truncate").prop("checked", false);
        }

        if (model.get("sampleCount") && model.get("sampleCount") != '0') {
            this.$("input[name='limit_num_rows']").prop("checked", true);
            this.$("input[name='sampleCount']").prop("disabled", false);
            this.$("input[name='sampleCount']").val(model.get("sampleCount"));
        }
    },

    onDestinationChosen: function() {
        this.clearErrors();
        this.updateExistingTableLink();
    },

    updateExistingTableLink: function() {
        var disableExisting = this.$(".new_table input:radio").prop("checked");

        var $tableName = this.$(".new_table input.name");
        $tableName.prop("disabled", !disableExisting);
        $tableName.closest("fieldset").toggleClass("disabled", !disableExisting);

        this.$("fieldset.existing_table").toggleClass("disabled", disableExisting);

        this.activeScheduleView = disableExisting ? this.scheduleViewNew : this.scheduleViewExisting;
        if (this.options.action === "create_schedule") {
            this.activeScheduleView.enable();
        }

        this.toggleExistingTableLink(!disableExisting);
        this.onInputFieldChanged();
        if (disableExisting && !this.existingTableSelected()) {
            this.$(".existing_table .dataset_picked").addClass("hidden");
        }
    },

    additionalContext: function() {
        return {
            allowNewTruncate: this.options.action !== "import_now",
            canonicalName: this.workspace.sandbox().schema().canonicalName(),
            showSchedule: this.showSchedule,
            submitText: this.submitText
        };
    },

    onInputFieldChanged: function(e) {
        this.showErrors(this.model);
        var changeType = e && e.type;
        if(changeType === "paste" || changeType === "cut") {
            //paste and cut events fire before they actually update the input field
            _.defer(_.bind(this.updateSubmitButton, this));
        } else {
            this.updateSubmitButton();
        }
    },

    updateSubmitButton: function() {
        var import_into_existing = this.$('.existing_table input:radio').attr("checked");
        if ((this.$('input.name').val().trim().length > 0 && !import_into_existing )
            || (this.existingTableSelected() && import_into_existing)) {
            this.$('button.submit').removeAttr('disabled');
        } else {
            this.$('button.submit').attr('disabled', 'disabled');
        }
    },

    onCheckboxClicked: function(e) {
        var $fieldSet = this.$("fieldset").not(".disabled");
        var enabled = $fieldSet.find("input[name=limit_num_rows]").prop("checked");
        var $limitInput = $fieldSet.find(".limit input:text");
        $limitInput.prop("disabled", !enabled);
        this.activeScheduleView.enable();
        this.onInputFieldChanged();
    },

    oneTimeImport: function() {
        return !this.showSchedule;
    },

    beginImport: function() {
        if (this.oneTimeImport()) {
            this.$("button.submit").startLoading("import.importing");
        } else {
            this.$("button.submit").startLoading("actions.saving");
        }

        this.model.set({ workspaceId: this.workspace.get("id") });

        saveOptions = {};
        if (this.options.action === "import_now") {
            saveOptions.method = "create";
        } else if (this.options.action === "edit_schedule") {
            saveOptions.method = "update";
        } else {
            // Error handler?
        }

        this.model.unset("sampleCount", {silent: true});
        this.model.save(this.getNewModelAttrs(), saveOptions);
    },

    importSaved: function() {
        if (this.oneTimeImport()) {
            this.dataset.setImport(undefined);
            chorus.toast("import.success");
        } else {
            chorus.toast("import.schedule.toast");
        }
        chorus.PageEvents.broadcast('importSchedule:changed', this.model);
        this.dataset.trigger('change');
        this.closeModal();
    },

    getNewModelAttrs: function() {
        var updates = {};
        var $enabledFieldSet = this.$("fieldset").not(".disabled");
        _.each($enabledFieldSet.find("input:text, input[type=hidden]"), function(i) {
            var input = $(i);
            if (input.is(":enabled") && input.closest(".schedule_widget").length === 0) {
                updates[input.attr("name")] = input.val() && input.val().trim();
            }
        });

        var $existingTable = $enabledFieldSet.find("a.dataset_picked");
        if($existingTable.length) {
            updates.toTable = $existingTable.data("dataset");
        }

        var $truncateCheckbox = $enabledFieldSet.find(".truncate");
        if ($truncateCheckbox.length) {
            updates.truncate = $truncateCheckbox.prop("checked") + "";
        }

        var useLimitRows = $enabledFieldSet.find(".limit input:checkbox").prop("checked");
        if (!useLimitRows) {
            updates.sampleCount = '';
        } else {
            updates.sampleCount = $enabledFieldSet.find("input[name='sampleCount']").val();
        }

        _.extend(updates, this.activeScheduleView.fieldValues());

        updates.importType = this.oneTimeImport() ? "oneTime" : "schedule";

        return updates;
    },

    onClickCancel: function() {
        this.model.clearErrors();
        this.closeModal();
    },

    existingTableSelected: function() {
        return this.$("a.dataset_picked").text() != t("dataset.import.select_dataset");
    }
});