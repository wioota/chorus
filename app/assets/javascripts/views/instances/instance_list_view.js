chorus.views.InstanceList = chorus.views.CheckableList.extend({
    constructorName: "InstanceListView",
    templateName: "instance_list",
    eventName: "instance",

    events: {
        "click li": "listItemClicked"
    },

    makeModel: function() {
        this.dataSources = this.options.dataSources;
        this.hadoopInstances = this.options.hadoopInstances;
        this.gnipInstances = this.options.gnipInstances;

        this.bindings.add(this.dataSources, "change", this.render);
        this.bindings.add(this.hadoopInstances, "change", this.render);
        this.bindings.add(this.gnipInstances, "change", this.render);

        this.bindings.add(this.dataSources, "reset", this.renderAndSetupCheckable);
        this.bindings.add(this.hadoopInstances, "reset", this.renderAndSetupCheckable);
        this.bindings.add(this.gnipInstances, "reset", this.renderAndSetupCheckable);
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
        this.hadoopInstances.each(function(hadoop) {
            this.collection.add(hadoop);
        }, this);
        this.gnipInstances.each(function(gnip) {
            this.collection.add(gnip);
        }, this);
    },

    setup: function() {
        this.collection = new chorus.collections.Base();
        this._super('setup', arguments);
        this.subscribePageEvent("instance:added", function(instance) {
            this.dataSources.fetchAll();
            this.hadoopInstances.fetchAll();
            this.gnipInstances.fetchAll();
            this.selectedInstance = instance;
        });
        this.bindings.add(this.dataSources, "remove", this.instanceDestroyed);
        this.bindings.add(this.hadoopInstances, "remove", this.instanceDestroyed);
        this.bindings.add(this.gnipInstances, "remove", this.instanceDestroyed);
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
            hadoop: this.hadoopInstances,
            dataSources: this.dataSources,
            gnip: this.gnipInstances
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
            hadoop_instance: this.hadoopInstances,
            gnip_instance: this.gnipInstances
        };
        var collection = map[target.data("type")];

        var instance = collection.get(target.data("instanceId"));
        this.selectedInstance = instance;
        chorus.PageEvents.broadcast("instance:selected", instance);
    }
});
