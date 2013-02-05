chorus.RequiredResources = chorus.collections.Base.extend({
    constructorName: "RequiredResources",

    allResponded: function() {
        return _.all(this.models, function(resource) {
            return resource.statusCode;
        });
    },

    add: function(resources, options) {
        this._super('add', [resources, _.extend({}, options, {silent: true})]);
        this.trigger('add', resources);

        resources = _.isArray(resources) ? resources.slice() : [resources];
        _.each(resources, _.bind(function (resource) {
            if(!resource.statusCode) {
                this.listenTo(resource, 'serverResponded', this.verifyResourcesResponded);
            }
        }, this));
    },

    verifyResourcesResponded: function() {
        if (this.allResponded()) {
            this.trigger("allResourcesResponded");
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