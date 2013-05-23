//= require ./work_flow_new_base_dialog

chorus.dialogs.WorkFlowNew = chorus.dialogs.WorkFlowNewBase.extend({
    subviews: {
        ".database_picker": "schemaPicker"
    },

    userWillPickSchema: true,

    setupSubviews: function(){
        this.schemaPicker = new chorus.views.SchemaPicker({
            showSchemaSection: false,
            defaultSchema: this.options.workspace.sandbox()
        });
        this.listenTo(this.schemaPicker, "change", this.toggleSubmitDisabled);
    },

    checkInput: function() {
        return this.getFileName().trim().length > 0 && !!this.schemaPicker.ready();
    },

    resourceAttributes: function () {
        return {
            fileName: this.getFileName(),
            databaseId: this.schemaPicker.getSelectedDatabase().id
        };
    }

});
