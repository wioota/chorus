//= require views/layout/checkable_list_view

chorus.views.DataSourceList = chorus.views.CheckableList.extend({
    constructorName: "DataSourceListView",
    templateName: "data_source_list",
    eventName: "data_source",

    events: {
        "click li": "listItemClicked"
    },

    makeModel: function() {
        this.dataSources = this.options.dataSources;
        this.hdfsDataSources = this.options.hdfsDataSources;
        this.gnipDataSources = this.options.gnipDataSources;

        this.bindings.add(this.dataSources, "change", this.render);
        this.bindings.add(this.hdfsDataSources, "change", this.render);
        this.bindings.add(this.gnipDataSources, "change", this.render);

        this.bindings.add(this.dataSources, "reset", this.renderAndSetupCheckable);
        this.bindings.add(this.hdfsDataSources, "reset", this.renderAndSetupCheckable);
        this.bindings.add(this.gnipDataSources, "reset", this.renderAndSetupCheckable);
    },

    catEntityTypeToModelID: function(model) {
        model.id = model.get('id') + '-' + model.get('entityType');
    },

    renderAndSetupCheckable: function(collection) {
        collection.each(this.catEntityTypeToModelID, this);
        this.render();
        this.setupCheckableCollection();
    },

    setupCheckableCollection: function() {
        this.collection.reset();
        this.dataSources.each(function(dataSource) {
            this.collection.add(dataSource);
        }, this);
        this.hdfsDataSources.each(function(hadoop) {
            this.collection.add(hadoop);
        }, this);
        this.gnipDataSources.each(function(gnip) {
            this.collection.add(gnip);
        }, this);
    },

    setup: function() {
        this.collection = new chorus.collections.Base();
        this._super('setup', arguments);
        this.subscribePageEvent("data_source:added", function(dataSource) {
            this.dataSources.fetchAll();
            this.hdfsDataSources.fetchAll();
            this.gnipDataSources.fetchAll();
            this.selectedDataSource = dataSource;
        });
        this.bindings.add(this.dataSources, "remove", this.dataSourceDestroyed);
        this.bindings.add(this.hdfsDataSources, "remove", this.dataSourceDestroyed);
        this.bindings.add(this.gnipDataSources, "remove", this.dataSourceDestroyed);
    },

    dataSourceDestroyed: function(model) {
        if(this.selectedDataSource.get("id") === model.get("id")) delete this.selectedDataSource;
        this.render();
    },

    postRender: function() {
        this.checkSelectedModels();
        if(this.selectedDataSource) {
            this.$('li[data-data-source-id=' + this.selectedDataSource.get("id") + ']' + '[data-type=' + this.selectedDataSource.get("entityType") + ']').click();
        } else {
            if(this.dataSources.loaded) {
                this.$('.data_source_provider li:first').click();
            }
        }
    },

    context: function() {
        var presenter = new chorus.presenters.DataSourceList({
            hadoop: this.hdfsDataSources,
            dataSources: this.dataSources,
            gnip: this.gnipDataSources
        });
        return presenter.present();
    },

    selectItem: function(target) {
        if(target.hasClass("selected")) {
            return;
        }

        this.$("li").removeClass("selected");
        target.addClass("selected");

        var map = {
            oracle_data_source: this.dataSources,
            gpdb_data_source: this.dataSources,
            hdfs_data_source: this.hdfsDataSources,
            gnip_data_source: this.gnipDataSources
        };
        var collection = map[target.data("type")];

        var dataSource = collection.get(target.data("dataSourceId"));
        this.selectedDataSource = dataSource;
        chorus.PageEvents.broadcast("data_source:selected", dataSource);
    }
});
