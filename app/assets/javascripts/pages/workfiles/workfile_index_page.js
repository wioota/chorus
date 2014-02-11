chorus.pages.WorkfileIndexPage = chorus.pages.Base.extend({
    constructorName: 'WorkfileIndexPage',
    helpId: "workfiles",

    setup: function(workspaceId) {
        this.collection = new chorus.collections.WorkfileSet([], {workspaceId: workspaceId});
        this.collection.fileType = "";
        this.collection.sortAsc("fileName");
        this.collection.fetchAll();

        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "workfiles"});
        this.buttonView = new chorus.views.WorkfileIndexPageButtons({model: this.workspace});
        this.mainContent = new chorus.views.MainContentList({
            modelClass: "Workfile",
            collection: this.collection,
            model: this.workspace,
            title: t("workfiles.title"),
            contentDetailsOptions: {
                multiSelect: true,
                buttonView: this.buttonView
            },
            contentOptions: {listItemOptions: {workspaceIdForTagLink: this.workspace.id} },
            linkMenus: {
                type: {
                    title: t("header.menu.filter.title"),
                    options: this.linkMenuOptions(),
                    event: "filter"
                },
                sort: {
                    title: t("workfiles.header.menu.sort.title"),
                    options: [
                        {data: "alpha", text: t("workfiles.header.menu.sort.alphabetically")},
                        {data: "date", text: t("workfiles.header.menu.sort.by_date")}
                    ],
                    event: "sort"
                }
            },
            search: {
                placeholder: t("workfile.search_placeholder"),
                eventName: "workfile:search"
            }
        });

        this.subscribePageEvent("workfile:search", function() {
            chorus.PageEvents.trigger('selectNone');
        });

        this.subscribePageEvent("workfile:selected", this.setModel);

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "workfile:checked",
            actions: [
                '<a class="edit_tags">{{t "sidebar.edit_tags"}}</a>'
            ],
            actionEvents: {
                'click .edit_tags': _.bind(function() {
                    new chorus.dialogs.EditTags({collection: this.multiSelectSidebarMenu.selectedModels}).launchModal();
                }, this)
            }
        });

        this.mainContent.contentHeader.bind("choice:filter", function(choice) {
            this.collection.attributes.fileType = choice;
            this.collection.fetchAll();
        }, this);

        this.mainContent.contentHeader.bind("choice:sort", function(choice) {
            var field = choice === "alpha" ? "fileName" : "userModifiedAt";
            this.collection.sortAsc(field);
            this.collection.fetchAll();
        }, this);

        this.requiredResources.add(this.workspace);
        this.breadcrumbs.requiredResources.add(this.workspace);
    },

    makeModel: function(workspaceId) {
        this.loadWorkspace(workspaceId);
    },

    setModel: function(workfile) {
        this.model = workfile;
        if(this.sidebar) {
            this.sidebar.teardown(true);
        }
        this.sidebar = chorus.views.WorkfileSidebar.buildFor({model: this.model});
        this.renderSubview('sidebar');
    },

    crumbs: function() {
        return [
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.workspaces"), url: '#/workspaces'},
            {label: this.workspace.loaded ? this.workspace.displayName() : "...", url: this.workspace.showUrl()},
            {label: t("breadcrumbs.workfiles.all")}
        ];
    },

    linkMenuOptions: function () {
        var items = [
            {data: "", text: t("workfiles.header.menu.filter.all")},
            {data: "SQL", text: t("workfiles.header.menu.filter.sql")},
            {data: "CODE", text: t("workfiles.header.menu.filter.code")},
            {data: "TEXT", text: t("workfiles.header.menu.filter.text")},
            {data: "IMAGE", text: t("workfiles.header.menu.filter.image")},
            {data: "OTHER", text: t("workfiles.header.menu.filter.other")}
        ];

        if (chorus.models.Config.instance().license().get("workflowEnabled")) {
            var workFlowsOption = {data: "WORK_FLOW", text: t("workfiles.header.menu.filter.work_flow")};
            items.splice(2, 0, workFlowsOption);
        }

        return items;
    }
});
