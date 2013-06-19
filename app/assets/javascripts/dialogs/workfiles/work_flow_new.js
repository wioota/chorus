//= require ./work_flow_new_base_dialog

chorus.dialogs.WorkFlowNew = chorus.dialogs.WorkFlowNewBase.extend({
    subviews: {
        ".database_picker": "executionLocationPicker"
    },

    userWillPickSchema: true,

    setupSubviews: function(){
        this.executionLocationPicker = new chorus.views.WorkFlowExecutionLocationPicker({
            database: this.options.workspace.sandbox().database()
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