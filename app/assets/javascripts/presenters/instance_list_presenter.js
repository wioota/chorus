chorus.presenters.InstanceList = function(options) {
    this.options = options;
};

_.extend(chorus.presenters.InstanceList.prototype, {
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

    presentModel: function(instance) {
        return {
            id: instance.get("id"),
            name: instance.get("name"),
            description: instance.get("description"),
            stateUrl: instance.stateIconUrl(),
            showUrl: instance.showUrl(),
            providerUrl: instance.providerIconUrl(),
            isOffline: instance.isOffline(),
            stateText: instance.stateText(),
            entityType: instance.get('entityType'),
            tags: instance.tags().models
        };
    }
});

