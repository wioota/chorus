chorus.plugins.push({
    WorkfileIndexPageButtons: {
        init: function(instance) {
            if(chorus.models.Config.instance().get("workFlowConfigured")) {
                instance.createActions = _.clone(instance.createActions);
                instance.createActions.push(
                    {className: 'create_work_flow', text: t("work_flows.actions.create_work_flow")}
                );

                instance.menuEvents = _.clone(instance.menuEvents);
                instance.menuEvents["a.create_work_flow"] = function() {
                    new chorus.dialogs.WorkFlowNew({workspace: this.model}).launchModal();
                };
            }
        }
    }
});
