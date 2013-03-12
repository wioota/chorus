chorus.views.InstanceList = chorus.views.CheckableList.extend({
    constructorName: "InstanceListView",
    templateName: "instance_list",
    eventName: "instance",

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
        this.subscribePageEvent("instance:added", function(instance) {
            this.dataSources.fetchAll();
            this.hdfsDataSources.fetchAll();
            this.gnipDataSources.fetchAll();
            this.selectedInstance = instance;
        });
        this.bindings.add(this.dataSources, "remove", this.instanceDestroyed);
        this.bindings.add(this.hdfsDataSources, "remove", this.instanceDestroyed);
        this.bindings.add(this.gnipDataSources, "remove", this.instanceDestroyed);
    },

    instanceDestroyed: function(model) {
        if(this.selectedInstance.get("id") === model.get("id")) delete this.selectedInstance;
        this.render();
    },

    postRender: function() {
        this.checkSelectedModels();
        if(this.selectedInstance) {
            this.$('li[data-instance-id=' + this.selectedInstance.get("id") + ']' + '[data-type=' + this.selectedInstance.get("entityType") + ']').click();
        } else {
            if(this.dataSources.loaded) {
                this.$('.instance_provider li:first').click();
            }
        }
    },

    context: function() {
        var presenter = new chorus.presenters.InstanceList({
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

        var instance = collection.get(target.data("instanceId"));
        this.selectedInstance = instance;
        chorus.PageEvents.broadcast("instance:selected", instance);
    }
});
