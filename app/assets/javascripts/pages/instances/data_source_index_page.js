chorus.pages.DataSourceIndexPage = chorus.pages.Base.extend({
    crumbs:[
        { label:t("breadcrumbs.home"), url:"#/" },
        { label:t("breadcrumbs.instances") }
    ],
    helpId: "instances",

    setup:function () {
        var dataSources = new chorus.collections.DataSourceSet();
        var hadoopInstances = new chorus.collections.HadoopInstanceSet();
        var gnipInstances = new chorus.collections.GnipInstanceSet();
        dataSources.fetchAll();
        hadoopInstances.fetchAll();
        gnipInstances.fetchAll();

        this.handleFetchErrorsFor(dataSources);
        this.handleFetchErrorsFor(hadoopInstances);
        this.handleFetchErrorsFor(gnipInstances);

        var options = {
            dataSources: dataSources,
            hadoopInstances: hadoopInstances,
            gnipInstances: gnipInstances
        };

        this.mainContent = new chorus.views.MainContentView({
            contentHeader: new chorus.views.StaticTemplate("default_content_header", {title:t("instances.title_plural")}),
            contentDetails: new chorus.views.InstanceIndexContentDetails(options),
            content: new chorus.views.InstanceList(options)
        });

        this.sidebar = new chorus.views.InstanceListSidebar();

        this.subscribePageEvent("instance:selected", this.setModel);
    },

    setModel:function (instance) {
        this.model = instance;
    }
});
