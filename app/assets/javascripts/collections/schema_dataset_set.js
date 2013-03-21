chorus.collections.SchemaDatasetSet = chorus.collections.LastFetchWins.include(
    chorus.Mixins.DataSourceCredentials.model
).extend({
    constructorName: 'SchemaDatasetSet',
    model:chorus.models.DynamicDataset,
    urlTemplate: "schemas/{{schemaId}}/datasets",

    urlParams: function() {
        if (this.attributes) {
            var paramsList = {};
            if(this.attributes.filter){
                paramsList['filter'] = this.attributes.filter;
            }
            if(this.attributes.tablesOnly) {
                paramsList['tablesOnly'] = this.attributes.tablesOnly;
            }
            return paramsList;
        }
    },

    search: function(term) {
        var self = this;
        self.attributes.filter = term;
        self.fetch({silent: true, success: function() { self.trigger('searched'); }});
    }
});
