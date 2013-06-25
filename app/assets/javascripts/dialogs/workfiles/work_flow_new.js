//= require ./work_flow_new_base_dialog

chorus.dialogs.WorkFlowNew = chorus.dialogs.WorkFlowNewBase.extend({
    subviews: {
        ".database_picker": "executionLocationPicker"
    },

    userWillPickSchema: true,

    setupSubviews: function(){
        var sandbox = this.options.workspace.sandbox();
        this.executionLocationPicker = new chorus.views.WorkFlowExecutionLocationPicker({
            database: sandbox && sandbox.database()
        });
        this.listenTo(this.executionLocationPicker, "change", this.toggleSubmitDisabled);
    },

    checkInput: function() {
        return this.getFileName().trim().length > 0 && !!this.executionLocationPicker.ready();
    },

    resourceAttributes: function () {
        var workFlowParams = {
            fileName: this.getFileName()
        };
        var selectedDataSource = this.executionLocationPicker.getSelectedDataSource();
        if (selectedDataSource.get('entityType') === 'gpdb_data_source') {
            workFlowParams['database_id'] = this.executionLocationPicker.getSelectedDatabase().id;
        } else {
            workFlowParams['hdfs_data_source_id'] = selectedDataSource.get('id');
        }
        return workFlowParams;
    }
});