chorus.dialogs.ChangeWorkFlowExecutionLocation = chorus.dialogs.Base.extend({
    templateName:"change_work_flow_execution_location",
    title: t("work_flows.change_execution_location.title"),

    subviews: {
        ".location_picker": "executionLocationPicker"
    },

    events: {
        "click button.submit": "save"
    },

    setup: function() {
        // this.model is the workfile (work flow)
        this.listenTo(this.model, "saved", this.saved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);

        var options;
        var executionLocation = this.model.executionLocation();
        if (executionLocation.get('entityType') === 'hdfs_data_source') {
            options = {
                dataSource: executionLocation
            };
        } else {
            options = {
                database: executionLocation,
                dataSource: executionLocation.dataSource()
            };
        }

        this.executionLocationPicker = new chorus.views.WorkFlowExecutionLocationPicker(options);

        this.listenTo(this.executionLocationPicker, "change", this.enableOrDisableSubmitButton);
        this.listenTo(this.executionLocationPicker, "error", this.showErrors);
        this.listenTo(this.executionLocationPicker, "clearErrors", this.clearErrors);
    },

    getWorkFlowParams: function() {
        var workFlowParams = {};
        var selectedDataSource = this.executionLocationPicker.getSelectedDataSource();
        if(selectedDataSource.get('entityType') === 'gpdb_data_source') {
            workFlowParams['database_id'] = this.executionLocationPicker.getSelectedDatabase().id;
        } else {
            workFlowParams['hdfs_data_source_id'] = selectedDataSource.get('id');
        }
        return workFlowParams;
    },

    save: function(e) {
        e.preventDefault();

        var params = this.getWorkFlowParams();
        this.model.save(params);
        this.$("button.submit").startLoading("actions.saving");
        this.$("button.cancel").prop("disabled", true);
    },

    saved: function() {
        this.closeModal();
    },

    saveFailed: function() {
        this.showErrors(this.model);
    },

    enableOrDisableSubmitButton: function() {
        this.$("button.submit").prop("disabled", !this.executionLocationPicker.ready());
    }
});