chorus.pages.DataSourceIndexPage = chorus.pages.Base.extend({
    crumbs:[
        { label:t("breadcrumbs.home"), url:"#/" },
        { label:t("breadcrumbs.instances") }
    ],
    helpId: "instances",

    setup:function () {
        var dataSources = new chorus.collections.DataSourceSet([], {all: true});
        var hdfsDataSources = new chorus.collections.HdfsDataSourceSet();
        var gnipInstances = new chorus.collections.GnipInstanceSet();
        dataSources.fetchAll();
        hdfsDataSources.fetchAll();
        gnipInstances.fetchAll();

        this.handleFetchErrorsFor(dataSources);
        this.handleFetchErrorsFor(hdfsDataSources);
        this.handleFetchErrorsFor(gnipInstances);

        var options = {
            dataSources: dataSources,
            hdfsDataSources: hdfsDataSources,
            gnipInstances: gnipInstances
        };

        this.mainContent = new chorus.views.MainContentView({
            contentHeader: new chorus.views.StaticTemplate("default_content_header", {title:t("instances.title_plural")}),
            contentDetails: new chorus.views.InstanceIndexContentDetails(options),
            content: new chorus.views.InstanceList(options)
        });

        this.sidebar = new chorus.views.InstanceListSidebar();

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "instance:checked",
            actions: [
                '<a class="edit_tags">{{t "sidebar.edit_tags"}}</a>'
            ],
            actionEvents: {
                'click .edit_tags': _.bind(function() {
                    new chorus.dialogs.EditTags({collection: this.multiSelectSidebarMenu.selectedModels}).launchModal();
                }, this)
            }
        });

        this.subscribePageEvent("instance:selected", this.setModel);
    },

    setModel:function (instance) {
        this.model = instance;
    }
});
