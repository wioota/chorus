chorus.views.AlpineWorkfileContentDetails = chorus.views.WorkfileContentDetails.extend({
    templateName: "alpine_workfile_content_details",
    additionalClass: "action_bar_highlighted",

    events: {
        'click a.change_workfile_database': 'changeWorkfileDatabase'
    },

    setup: function () {
        var members = this.model.workspace().members();
        this.listenTo(members, 'reset loaded', this.render);
        members.fetch();
    },

    additionalContext: function () {
        return  {
            workFlowShowUrl: this.model.workFlowShowUrl(),
            canOpen: this.model.canOpen(),
            dataSourceName: this.model.executionLocation().dataSource.name,
            databaseName: this.model.executionLocation().name,
            canUpdate: this.canUpdate()
        };
    },

    changeWorkfileDatabase: function(e) {
        e.preventDefault();
        new chorus.dialogs.ChangeWorkFlowExecutionLocation().launchModal();
    },

    canUpdate: function(){
        return this.model.workspace().canUpdate();
    }
});
