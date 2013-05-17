//= require ./workfile_index_page_buttons

chorus.views.WorkfileIndexPageButtons.prototype.createActions.push(
    {className: 'create_work_flow', text: t("work_flows.actions.create_work_flow")}
);

chorus.views.WorkfileIndexPageButtons.prototype.menuEvents["a.create_work_flow"] = function() {
    new chorus.dialogs.WorkFlowNew({workspace: this.model}).launchModal();
};