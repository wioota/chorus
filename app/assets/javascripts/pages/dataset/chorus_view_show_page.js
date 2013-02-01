chorus.pages.ChorusViewShowPage = chorus.pages.WorkspaceDatasetShowPage.extend({
    constructorName: "ChorusViewShowPage",

    setup: function() {
        this._super("setup", arguments);
        this.subscriptions.push(chorus.PageEvents.subscribe("dataset:cancelEdit", this.drawColumns, this));
    },

    makeModel: function(workspaceId, datasetId) {
        this.workspaceId = workspaceId;
        this.workspace = new chorus.models.Workspace({id: workspaceId});
        this.requiredResources.add(this.workspace);
        this.workspace.fetch();
        this.model = this.dataset = new chorus.models.ChorusView({ workspace: { id: workspaceId }, id: datasetId });
    },

    drawColumns: function() {
        this.bindings.remove(this.mainContent.contentDetails);
        this._super('drawColumns');
        this.bindings.add(this.mainContent.contentDetails, "dataset:edit", this.editChorusView);
    },

    editChorusView: function() {
        this.bindings.remove(this.mainContent.contentDetails);
        var sameHeader = this.mainContent.contentHeader;

        if (this.mainContent) {
            this.mainContent.teardown(true);
        }
        this.mainContent = new chorus.views.MainContentView({
            content: new chorus.views.DatasetEditChorusView({model: this.dataset}),
            contentHeader: sameHeader,
            contentDetails: new chorus.views.DatasetContentDetails({ dataset: this.dataset, collection: this.columnSet, inEditChorusView: true })
        });

        this.renderSubview('mainContent');
    },

    constructSidebarForType: function(type) {
        if(type === 'edit_chorus_view') {
            this.secondarySidebar = new chorus.views.DatasetEditChorusViewSidebar({model: this.model});
        } else {
            this._super('constructSidebarForType', arguments);
        }
    }
});
