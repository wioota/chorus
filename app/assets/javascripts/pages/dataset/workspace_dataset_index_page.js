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

        this.buttonView = new chorus.views.WorkspaceDatasetIndexPageButtons({model: this.workspace});
        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "datasets"});
        this.mainContent = new chorus.views.MainContentList({
            modelClass: "Dataset",
            collection: this.collection,
            model: this.workspace,
            useCustomList: true,
            title: t("dataset.title"),
            contentDetailsOptions: {
                multiSelect: true,
                buttonView: this.buttonView
            },
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
        this.breadcrumbs.requiredResources.add(this.workspace);
    },

    // This prevents a 422 on a single dataset from redirecting the entire page.
    unprocessableEntity: $.noop,

    makeModel: function(workspaceId) {
        this.loadWorkspace(workspaceId);
    },

    crumbs: function() {
        return [
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.workspaces"), url: '#/workspaces'},
            {label: this.workspace.displayName(), url: this.workspace.showUrl()},
            {label: t("breadcrumbs.workspaces_data")}
        ];
    },

    workspaceLoaded: function() {
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
