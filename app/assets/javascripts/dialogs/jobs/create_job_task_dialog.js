chorus.dialogs.CreateJobTask = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: 'CreateJobTask',
    templateName: 'create_job_task_dialog',
    title: t('create_job_task_dialog.title'),

    events: {
        "change select.action": "toggleTaskConfiguration",
        "change input:radio": "onExistingTableChosenAsDestination",
        "change input:checkbox": "onCheckboxClicked",
        "click .source a.dataset_picked": "launchSourceDatasetPickerDialog",
        "click .destination a.dataset_picked": "launchDestinationDatasetPickerDialog"
    },

    setup: function () {
        this.workspace = this.options.job.workspace();
        this.model = new chorus.models.JobTask({workspace: this.workspace, job: this.options.job});

        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input",
            checkInput: _.bind(this.checkInput, this)
        });
    },

    postRender: function () {
        this.updateExistingTableLink();
    },

    checkInput: function () {
        var importIntoExisting = this.$(".choose_table input:radio").prop("checked");
        var newTableNameGiven = this.$('input.name').val().trim().length > 0;

        var existingDestinationPicked = importIntoExisting && this.destinationTableHasBeenPicked;
        var newDestinationNamed = (!importIntoExisting && newTableNameGiven);

        var sourcePicked = this.sourceTableHasBeenPicked;
        var destinationPicked = existingDestinationPicked || newDestinationNamed;

        var validLimit = this.limitIsChecked() ? this.limitIsValid() : true;
        return sourcePicked && destinationPicked && validLimit;
    },

    isNewTable: function () {
        return this.$('.new_table input:radio').prop('checked');
    },

    onExistingTableChosenAsDestination: function () {
        this.clearErrors();
        this.updateExistingTableLink();
    },

    updateExistingTableLink: function () {
        var destinationIsNewTable = this.$(".new_table input:radio").prop("checked");

        var $tableNameField = this.$(".new_table input.name");
        $tableNameField.prop("disabled", !destinationIsNewTable);

        this.$(".truncate").prop("disabled", this.isNewTable());

        this.enableDestinationLink(!destinationIsNewTable);
        this.showErrors(this.model);
        this.toggleSubmitDisabled();
    },

    enableDestinationLink: function (enable) {
        var $a = this.$(".destination a.dataset_picked");
        var $span = this.$(".destination span.dataset_picked");

        if (enable) {
            $a.removeClass("hidden");
            $span.addClass("hidden");
        } else {
            $a.addClass("hidden");
            $span.removeClass("hidden");
        }
    },

    sourceTableHasBeenPicked: false,
    destinationTableHasBeenPicked: false,

    limitIsChecked: function () {
        return this.$("input[name=limit_num_rows]").prop("checked");
    },

    limitIsValid: function () {
        var limit = parseInt(this.$(".limit input[type=text]").val(), 10);

        return isNaN(limit) ? false : limit > 0;
    },

    onCheckboxClicked: function (e) {
        this.$(".limit input:text").prop("disabled", !this.limitIsChecked());
        this.toggleSubmitDisabled();
    },

    toggleTaskConfiguration: function (e) {
        var selectedAction = this.$('select.action').val();
        this.$('.import').toggleClass('hidden', (selectedAction !== 'import_source_data'));
    },

    datasetsChosen: function (datasets, target) {
        if (target === '.destination') {
            this.destinationTableHasBeenPicked = true;
        }
        if (target === '.source') {
            this.sourceTableHasBeenPicked = true;
        }

        this.changeSelectedDataset(datasets && datasets[0] && datasets[0].name(), target);
    },

    changeSelectedDataset: function (name, target) {
        if (name) {
            this.selectedDatasetName = name;
            this.$(target + " a.dataset_picked").text(_.prune(name, 20));
            this.$(target + " span.dataset_picked").text(_.prune(name, 20));
            this.toggleSubmitDisabled();
        }
    },

    create: function () {
//        this.$("button.submit").startLoading('actions.saving');
//        this.model.unset("sampleCount", {silent: true});
//        this.model.save(this.fieldValues(), {wait: true});
    },

    fieldValues: function () {
        var updates = {};

//        _.each(this.$("input:text, input[type=hidden]"), function(i) {
//            var input = $(i);
//            if(input.is(":enabled") && input.closest(".schedule_widget").length === 0) {
//                updates[input.attr("name")] = input.val() && input.val().trim();
//            }
//        });
//
//        updates.newTable = this.isNewTable() + "";
//        updates.schemaId = this.schema.id;
//
//        if(this.isNewTable()) {
//            updates.toTable = this.$("input[name=toTable]").val();
//        } else {
//            updates.toTable = this.selectedDatasetName;
//        }
//
//        var $truncateCheckbox = this.$(".truncate");
//        if($truncateCheckbox.length) {
//            updates.truncate = $truncateCheckbox.prop("checked") + "";
//        }
//
//        var useLimitRows = this.$(".limit input:checkbox").prop("checked");
//        if(!useLimitRows) {
//            updates.sampleCount = '';
//        } else {
//            updates.sampleCount = this.$("input[name='sampleCount']").val();
//        }

        return updates;
    },

    submit: $.noop,

    launchDatasetPickerDialog: function (e, target) {
        e.preventDefault();
        if (this.saving) {
            return;
        }

        var tables = this.workspace.sandboxTables({allImportDestinations: true});
        var datasetDialog = new chorus.dialogs.DatasetsPicker({ collection: tables });

        this.listenTo(datasetDialog, "datasets:selected", function (datasets) {
            return this.datasetsChosen(datasets, target);
        });

        this.launchSubModal(datasetDialog);
    },

    launchSourceDatasetPickerDialog: function (e) {
        this.launchDatasetPickerDialog(e, '.source');
    },

    launchDestinationDatasetPickerDialog: function (e) {
        this.launchDatasetPickerDialog(e, '.destination');
    }
});
