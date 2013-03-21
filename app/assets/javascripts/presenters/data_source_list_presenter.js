chorus.presenters.DataSourceList = function(options) {
    this.options = options;
};

_.extend(chorus.presenters.DataSourceList.prototype, {
    present: function() {
        this.dataSources = this.options.dataSources.map(function(model) {
            return this.presentModel(model);
        }, this);

        this.hadoop = this.options.hadoop.map(function(model) {
            return this.presentModel(model);
        }, this);

        this.gnip = this.options.gnip.map(function(model) {
            return this.presentModel(model);
        }, this);

        this.hasDataSources = this.dataSources.length > 0;
        this.hasHadoop = this.hadoop.length > 0;
        this.hasGnip = this.gnip.length > 0;

        return this;
    },

    presentModel: function(dataSource) {
        return {
            id: dataSource.get("id"),
            name: dataSource.get("name"),
            description: dataSource.get("description"),
            stateUrl: dataSource.stateIconUrl(),
            showUrl: dataSource.showUrl(),
            providerUrl: dataSource.providerIconUrl(),
            isOffline: dataSource.isOffline(),
            stateText: dataSource.stateText(),
            entityType: dataSource.get('entityType'),
            tags: dataSource.tags().models
        };
    }
});

