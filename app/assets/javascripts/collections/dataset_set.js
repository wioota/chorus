chorus.collections.DatasetSet = chorus.collections.LastFetchWins.include(
    chorus.Mixins.InstanceCredentials.model
).extend({
    constructorName: 'DatasetSet',
    model:chorus.models.DynamicDataset,
    urlTemplate: "schemas/{{schemaId}}/datasets",

    urlParams: function() {
        if (this.attributes && this.attributes.filter) {
            return {entitySubtype: "meta", filter: this.attributes.filter};
        } else {
            return {entitySubtype: "meta"};
        }
    },

    search: function(term) {
        var self = this;
        self.attributes.filter = term;
        self.fetch({silent: true, success: function() { self.trigger('searched'); }});
    }
});
