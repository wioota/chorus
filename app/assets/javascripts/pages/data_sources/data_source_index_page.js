chorus.pages.DataSourceIndexPage = chorus.pages.Base.extend({
    crumbs:[
        { label:t("breadcrumbs.home"), url:"#/" },
        { label:t("breadcrumbs.instances") }
    ],
    helpId: "instances",

    setup:function () {
        var dataSources = new chorus.collections.DataSourceSet([], {all: true});
        var hdfsDataSources = new chorus.collections.HdfsDataSourceSet();
        var gnipDataSources = new chorus.collections.GnipDataSourceSet();
        dataSources.fetchAll();
        hdfsDataSources.fetchAll();
        gnipDataSources.fetchAll();

        this.handleFetchErrorsFor(dataSources);
        this.handleFetchErrorsFor(hdfsDataSources);
        this.handleFetchErrorsFor(gnipDataSources);

        var options = {
            dataSources: dataSources,
            hdfsDataSources: hdfsDataSources,
            gnipDataSources: gnipDataSources
        };

        this.mainContent = new chorus.views.MainContentView({
            contentHeader: new chorus.views.StaticTemplate("default_content_header", {title:t("instances.title_plural")}),
            contentDetails: new chorus.views.DataSourceIndexContentDetails(options),
            content: new chorus.views.DataSourceList(options)
        });

        this.sidebar = new chorus.views.DataSourceListSidebar();

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "data_source:checked",
            actions: [
                '<a class="edit_tags">{{t "sidebar.edit_tags"}}</a>'
            ],
            actionEvents: {
                'click .edit_tags': _.bind(function() {
                    new chorus.dialogs.EditTags({collection: this.multiSelectSidebarMenu.selectedModels}).launchModal();
                }, this)
            }
        });

        this.subscribePageEvent("data_source:selected", this.setModel);
    },

    setModel:function (dataSource) {
        this.model = dataSource;
    }
});
