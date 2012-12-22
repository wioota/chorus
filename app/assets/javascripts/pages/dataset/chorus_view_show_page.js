chorus.pages.ChorusViewShowPage = chorus.pages.WorkspaceDatasetShowPage.extend({
    constructorName: "ChorusViewShowPage",

    makeModel: function(workspaceId, datasetId) {
        this.workspaceId = workspaceId;
        this.workspace = new chorus.models.Workspace({id: workspaceId});
        this.requiredResources.add(this.workspace);
        this.workspace.fetch();
        this.model = this.dataset = new chorus.models.ChorusView({ workspace: { id: workspaceId }, id: datasetId });
    },

    drawColumns: function() {
        this._super('drawColumns');

        this.mainContent.contentDetails.bind("dataset:edit", this.editChorusView, this);
    },

    editChorusView: function() {
        var sameHeader = this.mainContent.contentHeader;
        this.mainContent = new chorus.views.MainContentView({
            content: new chorus.views.DatasetEditChorusView({model: this.dataset}),
            contentHeader: sameHeader,
            contentDetails: new chorus.views.DatasetContentDetails({ dataset: this.dataset, collection: this.columnSet, inEditChorusView: true })
        });

        chorus.PageEvents.subscribe("dataset:cancelEdit", this.drawColumns, this);

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
