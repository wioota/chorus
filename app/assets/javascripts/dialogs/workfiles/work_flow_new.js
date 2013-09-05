//= require ./work_flow_new_base_dialog

chorus.dialogs.WorkFlowNew = chorus.dialogs.WorkFlowNewBase.extend({
    constructorName: 'WorkFlowNewDialog',
    additionalClass: 'dialog_wide',

    subviews: {
        ".database_picker": "executionLocationList"
    },

    userWillPickSchema: true,

    setupSubviews: function(){
        var sandbox = this.options.workspace.sandbox();
        this.executionLocationList = new chorus.views.WorkFlowExecutionLocationPickerList({
            dataSource: sandbox && sandbox.database().dataSource(),
            database: sandbox && sandbox.database()
        });
        this.listenTo(this.executionLocationList, "change", this.toggleSubmitDisabled);
    },

    checkInput: function() {
        return this.getFileName().trim().length > 0 && !!this.executionLocationList.ready();
    },

    resourceAttributes: function () {
        var workFlowParams = {
            fileName: this.getFileName()
        };
        var selectedDataSource = this.executionLocationList.getSelectedDataSources()[0];
        if (selectedDataSource.get('entityType') === 'gpdb_data_source') {
            workFlowParams['database_id'] = this.executionLocationList.getSelectedDatabases()[0].id;
        } else {
            workFlowParams['hdfs_data_source_id'] = selectedDataSource.get('id');
        }
        return workFlowParams;
    }
});