chorus.RequiredResources = chorus.collections.Base.extend({
    constructorName: "RequiredResources",

    allLoaded:function () {
        return _.all(this.models, function (resource) {
            return resource.loaded;
        });
    },

    add:function (obj, options) {
        this._super('add', [obj, _.extend({}, options, {silent: true})]);
        this.trigger('add', obj);
    },

    _prepareModel:function (obj) {
        if (!obj.cid) {
            obj.cid = _.uniqueId('rr');
        }
        return obj;
    },

    cleanUp: function() {
        this.unbind();
        this.each(function(resource) { resource.unbind() });
        this.reset([], { silent: true });
    }
});

chorus.RequiredResources.prototype.push = chorus.RequiredResources.prototype.add;
