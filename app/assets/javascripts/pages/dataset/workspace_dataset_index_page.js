chorus.pages.WorkspaceDatasetIndexPage = chorus.pages.Base.extend({
    constructorName: "WorkspaceDatasetIndexPage",
    helpId: "datasets",

    setup: function(workspaceId) {
        this.collection = new chorus.collections.WorkspaceDatasetSet([], {workspaceId: workspaceId});
        this.collection.sortAsc("objectName");
        this.collection.fetch();
        this.handleFetchErrorsFor(this.collection);
        this.workspace.members().fetchIfNotLoaded();

        this.subscribePageEvent("dataset:selected", function(dataset) {
            this.model = dataset;
        });

        this.subscribePageEvent("csv_import:started", function() {
            this.collection.fetch();
        });

        this.listenTo(this.collection, 'searched', function() {
            this.mainContent.content.render();
            this.mainContent.contentFooter.render();
            this.mainContent.contentDetails.updatePagination();
        });

        var onTextChangeFunction = _.debounce(_.bind(function(e) {
            this.mainContent.contentDetails.startLoading(".count");
            this.collection.search($(e.target).val());
        }, this), 300);

        this.buildSidebar();
        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "datasets"});
        this.mainContent = new chorus.views.MainContentList({
            modelClass: "Dataset",
            collection: this.collection,
            model: this.workspace,
            useCustomList: true,
            title: t("dataset.title"),
            contentDetailsOptions: { multiSelect: true },
            search: {
                placeholder: t("workspace.search"),
                onTextChange: onTextChangeFunction
            },
            linkMenus: {
                type: {
                    title: t("header.menu.filter.title"),
                    options: [
                        {data: "", text: t("dataset.header.menu.filter.all")},
                        {data: "SOURCE_TABLE", text: t("dataset.header.menu.filter.source")},
                        {data: "CHORUS_VIEW", text: t("dataset.header.menu.filter.chorus_views")},
                        {data: "SANDBOX_DATASET", text: t("dataset.header.menu.filter.sandbox")}
                    ],
                    event: "filter"
                }
            }
        });

        this.mainContent.contentHeader.bind("choice:filter", function(choice) {
            this.collection.attributes.type = choice;
            this.collection.fetch();
        }, this);

        this.sidebar = new chorus.views.DatasetSidebar({ workspace: this.workspace, listMode: true });

        this.onceLoaded(this.workspace, this.workspaceLoaded);
    },


    // This prevents a 422 on a single dataset from redirecting the entire page.
    unprocessableEntity: $.noop,

    makeModel: function(workspaceId) {
        this.loadWorkspace(workspaceId);
    },

    buildPrimaryActionPanel: function () {
        this.primaryActionPanel = new chorus.views.PrimaryActionPanel({
            actions: this.primaryActions(),
            pageModel: this.workspace
        });
    },

    workspaceCanUpdate: function () {

        return this.workspace.loaded && this.workspace.canUpdate() && this.workspace.isActive();
    },

    primaryActions: function () {
        if (!this.workspaceCanUpdate()) return [];

        var actions =  [
            {name: 'create_hdfs_dataset', target: chorus.dialogs.CreateHdfsDataset},
            {name: 'browse_data_sources', target: '/data_sources'}
        ];

        var fileImport = {name: 'import_file', target: chorus.dialogs.WorkspaceFileImport};

        this.workspace.sandbox() && actions.push(fileImport);

        return actions;
    },

    workspaceLoaded: function() {
        this.buildPrimaryActionPanel();
        this.mainContent.contentHeader.options.sandbox = this.workspace.sandbox();
        this.render();

        if (this.workspace.isActive()) {
            this.mainContent.content.options.hasActiveWorkspace = true;
        }

        if(this.workspace.sandbox()) {
            this.dataSource = this.workspace.sandbox().dataSource();
            this.account = this.workspace.sandbox().dataSource().accountForCurrentUser();

            this.listenTo(this.account, "loaded", this.checkAccount);

            this.account.fetchIfNotLoaded();
        }
        this.mainContent.contentDetails.render();
        this.onceLoaded(this.workspace.members(), _.bind(function () {
            this.multiSelectSidebarMenu.render();
        }, this));
    },

    checkAccount: function() {
        if (!this.dataSource.isShared() && !this.account.get('id')) {
            if (!chorus.session.sandboxPermissionsCreated[this.workspace.get("id")]) {
                this.dialog = new chorus.dialogs.WorkspaceDataSourceAccount({model: this.account, pageModel: this.workspace});
                this.dialog.launchModal();
                this.account.bind('saved', function() {
                    this.collection.fetch();
                }, this);
                chorus.session.sandboxPermissionsCreated[this.workspace.get("id")] = true;
            }
        }
    },

    sidebarMultiselectActions: function () {
        var actions = [ '<a class="edit_tags">{{t "sidebar.edit_tags"}}</a>' ];

        if (chorus.models.Config.instance().license().workflowEnabled() && this.workspace.currentUserCanCreateWorkFlows()) {
            actions.push('<a class="new_work_flow">{{t "sidebar.new_work_flow"}}</a>');
        }

        var selectedModels = this.multiSelectSidebarMenu.selectedModels;
        if (selectedModels.all(function(model) { return model.get("entitySubtype") === "SOURCE_TABLE"; })) {
            actions.push('<a class="disassociate_dataset">{{t "actions.delete_association"}}</a>');
        }
        return actions;
    },

    sidebarMultiselectActionEvents: function () {
        return {
            'click .edit_tags': _.bind(function () {
                new chorus.dialogs.EditTags({collection: this.multiSelectSidebarMenu.selectedModels}).launchModal();
            }, this),
            'click .new_work_flow': _.bind(function () {
                new chorus.dialogs.WorkFlowNewForDatasetList({workspace: this.workspace, collection: this.multiSelectSidebarMenu.selectedModels}).launchModal();
            }, this),
            'click .disassociate_dataset': _.bind(function () {
                // Send the delete confirm dialog a WorkspaceDatasetSet that is a list of selected workspaces (this.multiSelectSidebarMenu.selectedModels)
                new chorus.alerts.DatasetDisassociateMultiple({pageModel: this.multiSelectSidebarMenu.selectedModels}).launchModal();
            }, this)
        };
    },

    buildSidebar: function () {
        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "dataset:checked",
            actions: _.bind(this.sidebarMultiselectActions, this),
            actionEvents: this.sidebarMultiselectActionEvents()
        });
    }
});
