chorus.pages.KaggleUserIndexPage = chorus.pages.Base.extend({
    constructorName: "KaggleUserIndexPage",
    additionalClass: 'kaggle_user_list',

    setup: function(workspaceId) {
        this.workspaceId = workspaceId;
        this.workspace = new chorus.models.Workspace({ id: workspaceId });
        this.dependOn(this.workspace);
        this.workspace.fetch();
        this.collection = new chorus.collections.KaggleUserSet([]);
        this.dependOn(this.collection);
        this.collection.fetch();

        this.mainContent = new chorus.views.MainContentList({
            modelClass: "KaggleUser",
            collection: this.collection,
            contentHeader: new chorus.views.KaggleHeader(),
            contentDetails: new chorus.views.KaggleUserListContentDetails({collection: this.collection})
        });

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "kaggleUser:checked",
            actions: [
                '<a class="send_message" href="#">{{t "actions.send_kaggle_message"}}</a>'
            ],
            actionEvents: {
                'click .send_message': _.bind(function() {
                    new chorus.dialogs.ComposeKaggleMessage({recipients: this.multiSelectSidebarMenu.selectedModels, workspace: this.workspace}).launchModal();
                }, this)
            }
        });

        this.sidebar = new chorus.views.KaggleUserSidebar({workspace: this.workspace});

        chorus.PageEvents.subscribe("filterKaggleUsers", this.filterKaggleUsers, this);
    },

    crumbs: function() {
        return [
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.workspaces"), url: "#/workspaces"},
            {label: this.workspace && this.workspace.loaded ? this.workspace.displayShortName() : "...", url: this.workspace && this.workspace.showUrl()},
            {label: "Kaggle"}
        ];
    },

    filterKaggleUsers: function(filterCollection) {
        var paramArray = _.compact(filterCollection.map(function(model) {
            return model.filterParams();
        }));
        this.collection.urlParams = {'filters[]': paramArray};
        this.collection.fetch();
    }
});