chorus.pages.DashboardPage = chorus.pages.Base.extend({
    constructorName: "DashboardPage",

    crumbs:[
        { label:t("breadcrumbs.home") }
    ],
    helpId: "dashboard",

    setup:function () {
        this.collection = this.workspaceSet = new chorus.collections.WorkspaceSet();
        this.workspaceSet.attributes.userId = chorus.session.user().id;
        this.workspaceSet.attributes.showLatestComments = true;
        this.workspaceSet.attributes.succinct = true;
        this.workspaceSet.attributes.active = true;
        this.workspaceSet.sortAsc("name");
        this.workspaceSet.fetchAll();

        this.dataSourceSet = new chorus.collections.DataSourceSet([]);
        this.dataSourceSet.attributes.succinct = true;
        this.hdfsDataSourceSet = new chorus.collections.HdfsDataSourceSet([]);
        this.hdfsDataSourceSet.attributes.succinct = true;
        this.gnipDataSourceSet = new chorus.collections.GnipDataSourceSet([]);
        this.gnipDataSourceSet.attributes.succinct = true;

        this.subscribePageEvent("data_source:added", function() { this.fetchDataSources(); });

        this.fetchDataSources();
        this.model = chorus.session.user();

        this.userSet = new chorus.collections.UserSet();
        this.userSet.bindOnce("loaded", function() {
            this.userCount = this.userSet.pagination.records;
            this.showUserCount();
        }, this);
        this.userSet.fetchAll();
    },

    fetchDataSources: function() {
        this.bindings.add(this.dataSourceSet, "loaded", this.mergeDataSources);
        this.dataSourceSet.fetchAll();

        this.bindings.add(this.hdfsDataSourceSet, "loaded", this.mergeDataSources);
        this.hdfsDataSourceSet.fetchAll();

        this.bindings.add(this.gnipDataSourceSet, "loaded", this.mergeDataSources);
        this.gnipDataSourceSet.fetchAll();
    },

    dataSourcesLoaded: function() {
        return (this.dataSourceSet && this.dataSourceSet.loaded &&
            this.hdfsDataSourceSet && this.hdfsDataSourceSet.loaded &&
                this.gnipDataSourceSet && this.gnipDataSourceSet.loaded);
    },

    mergeDataSources: function() {
        if(this.dataSourcesLoaded()) {
            var wrapDataSources = function(set) {
                return _.map(set, function(dataSource) {
                    return new chorus.models.Base({ theDataSource: dataSource });
                });
            };

            var proxyDataSources = wrapDataSources(this.dataSourceSet.models);
            var proxyHdfsDataSources = wrapDataSources(this.hdfsDataSourceSet.models);
            var proxyGnipDataSources = wrapDataSources(this.gnipDataSourceSet.models);

            this.arraySet = new chorus.collections.Base();
            this.arraySet.comparator = function(dataSourceWrapper) {
                return dataSourceWrapper.get("theDataSource").name().toLowerCase();
            };

            this.arraySet.add(proxyDataSources);
            this.arraySet.add(proxyHdfsDataSources);
            this.arraySet.add(proxyGnipDataSources);
            this.arraySet.loaded = true;

            this.mainContent = new chorus.views.Dashboard({
                collection: this.workspaceSet,
                dataSourceSet: this.arraySet
            });
            this.render();
        }
    },

    showUserCount: function() {
        if (this.userCount) {
            this.$("#user_count a").text(t("dashboard.user_count", {count: this.userCount}));
            this.$("#user_count").removeClass("hidden");
        }
    },

    postRender:function () {
        this._super('postRender');
        this.$(".pill").insertAfter(this.$("#breadcrumbs"));
        this.$("#sidebar_wrapper").remove();
    }
});
