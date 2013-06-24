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
        return {
            fileName: this.getFileName(),
            databaseId: this.executionLocationPicker.getSelectedDatabase().id
        };
    }
});