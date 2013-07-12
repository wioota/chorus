chorus.pages.HdfsDatasetShowPage = chorus.pages.Base.extend({
    constructorName: "HdfsDatasetShowPage",
    helpId: "dataset",

    crumbs: function() {
        return [
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.workspaces"), url: '#/workspaces'},
            {label: this.workspace.displayName(), url: this.workspace.showUrl()},
            {label: t("breadcrumbs.workspaces_data"), url: this.workspace.datasets().showUrl()},
            {label: this.model.name()}
        ];
    },

    makeModel: function(workspaceId, datasetId) {
        this.loadWorkspace(workspaceId, {required: true});
        this.model = this.dataset = new chorus.models.HdfsDataset({ workspace: { id: workspaceId }, id: datasetId });
    },

    setup: function() {
        this.model.fetch();
        this.breadcrumbs.requiredResources.add(this.dataset);

        this.mainContent = new chorus.views.MainContentView({
            model:this.model,
            content:new chorus.views.ReadOnlyTextContent({model:this.model}),
            contentHeader:new chorus.views.DatasetShowContentHeader({ model:this.model }),
            contentDetails:new chorus.views.HdfsDatasetContentDetails({ model:this.model })
        });

        this.sidebar = new chorus.views.DatasetSidebar({ model: this.model });
        this.listenTo(this.model, "invalidated", function() { this.model.fetch(); });
    }

});
