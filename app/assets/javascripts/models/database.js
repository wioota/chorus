chorus.models.Database = chorus.models.Base.include(
    chorus.Mixins.InstanceCredentials.model
).extend({
    constructorName: "Database",
    showUrlTemplate: "databases/{{id}}",
    urlTemplate: "databases/{{id}}",

    instance: function() {
        var instance = this._instance || new chorus.models.GpdbInstance(this.get("instance"));
        if(this.loaded) {
            this._instance = instance;
        }
        return instance;
    },

    schemas: function() {
        var schema = this._schemas || new chorus.collections.SchemaSet([], { databaseId: this.get('id') });
        if(this.loaded) {
            this._schemas = schema;
        }
        return schema;
    }
});