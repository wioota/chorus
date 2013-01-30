chorus.RequiredResources = chorus.collections.Base.extend({
    constructorName: "RequiredResources",

    allLoaded: function() {
        return _.all(this.models, function(resource) {
            return resource.loaded;
        });
    },

    add: function(resources, options) {
        this._super('add', [resources, _.extend({}, options, {silent: true})]);
        this.trigger('add', resources);

        resources = _.isArray(resources) ? resources.slice() : [resources];
        _.each(resources, _.bind(function (resource) {
            if(!resource.loaded) {
                this.listenTo(resource, 'loaded', this.verifyResourcesLoaded);
            }
        }, this));
    },

    verifyResourcesLoaded: function() {
        if (this.allLoaded()) {
            this.trigger("allResourcesLoaded");
        }
    },

    _prepareModel: function(obj) {
        if(!obj.cid) {
            obj.cid = _.uniqueId('rr');
        }
        return obj;
    },

    cleanUp: function(context) {
        this.unbind(null, null, context);
        this.stopListening();
        this.each(function(resource) {
            resource.unbind(null, null, context);
        });
        this.reset([], { silent: true });
    }
});

chorus.RequiredResources.prototype.push = chorus.RequiredResources.prototype.add;