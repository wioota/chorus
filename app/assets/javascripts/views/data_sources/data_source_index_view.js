chorus.views.DataSourceIndex = chorus.views.Base.extend({
    constructorName: "DataSourceIndexView",
    templateName: "data_source_index",
    eventName: "data_source",

    subviews: {
        '.data_source': 'dataSourceList',
        '.hdfs_data_source': 'hdfsDataSourceList',
        '.gnip_data_source': 'gnipDataSourceList'
    },

    makeModel: function() {
        this.dataSources = this.options.dataSources;
        this.hdfsDataSources = this.options.hdfsDataSources;
        this.gnipDataSources = this.options.gnipDataSources;
        this.selectedModels = new (chorus.collections.Base.include(chorus.Mixins.MultiModelSet))();
    },

    setup: function() {
        this._super('setup', arguments);
        this.dataSourceList = this.buildListView('data_source', this.dataSources);
        this.registerSubView(this.dataSourceList);

        this.hdfsDataSourceList = this.buildListView('hdfs_data_source', this.hdfsDataSources);
        this.registerSubView(this.hdfsDataSourceList);

        this.gnipDataSourceList = this.buildListView('gnip_data_source', this.gnipDataSources);
        this.registerSubView(this.gnipDataSourceList);

        this.bindings.add(this.dataSources, 'loaded', this.selectModel);
        this.bindings.add(this.hdfsDataSources, 'loaded', this.selectModel);
        this.bindings.add(this.gnipDataSources, 'loaded', this.selectModel);

        this.subscribePageEvent("data_source:added", function(dataSource) {
            this.dataSources.loaded = false;
            this.hdfsDataSources.loaded = false;
            this.gnipDataSources.loaded = false;
            this.dataSources.fetchAll();
            this.hdfsDataSources.fetchAll();
            this.gnipDataSources.fetchAll();
            this.selectedModel = dataSource;
        });
    },

    buildListView: function(entityType, collection) {
        return new chorus.views.DataSourceList({
            entityType: entityType,
            collection: collection,
            selectedModels: this.selectedModels
        });
    },

    selectModel: function() {
        if (this.dataSources.loaded && this.hdfsDataSources.loaded && this.gnipDataSources.loaded) {
            if (this.selectedModel) {
                chorus.PageEvents.broadcast('selected', this.selectedModel);
            } else {
                this.$("li:first").click();
            }
        }
    }
});
