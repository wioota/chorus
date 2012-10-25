chorus.collections.GpdbInstanceSet = chorus.collections.Base.extend({
    constructorName: "GpdbInstanceSet",
    model: chorus.models.GpdbInstance,
    urlTemplate: "gpdb_instances/",

    urlParams: function() {
        return _.extend(this._super('urlParams') || {}, {accessible: this.attributes.accessible});
    },

    comparator: function(instance) {
        return instance.get("name").toLowerCase();
    }
});
