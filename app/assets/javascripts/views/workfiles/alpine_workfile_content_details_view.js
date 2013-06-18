chorus.views.AlpineWorkfileContentDetails = chorus.views.WorkfileContentDetails.extend({
    templateName: "alpine_workfile_content_details",
    additionalClass: "action_bar_highlighted",

    events: {
        'click a.change_workfile_database': 'changeWorkfileDatabase',
        'click .open_file': 'navigateToWorkFlow'
    },

    setup: function () {
        var members = this.model.workspace().members();
        this.listenTo(members, 'reset loaded', this.render);
        members.fetch();
    },

    additionalContext: function () {
        var ctx = {
            workFlowShowUrl: this.model.workFlowShowUrl(),
            canOpen: this.model.canOpen(),
            canUpdate: this.canUpdate()
        };

        if (this.model.executionLocation()) {
            ctx.dataSourceName = this.model.executionLocation().dataSource.name;
            ctx.databaseName = this.model.executionLocation().name;
        }
        return ctx;
    },

    changeWorkfileDatabase: function(e) {
        e.preventDefault();
        new chorus.dialogs.ChangeWorkFlowExecutionLocation().launchModal();
    },

    canUpdate: function(){
        return this.model.workspace().isActive() && this.model.workspace().canUpdate();
    },

    navigateToWorkFlow:function(){
        chorus.router.navigate(this.model.workFlowShowUrl());
    }
});
