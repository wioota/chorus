chorus.models.Schema = chorus.models.Base.extend({
    constructorName: "Schema",
    showUrlTemplate: "schemas/{{id}}",
    urlTemplate: "schemas/{{id}}",

    functions: function() {
        this._schemaFunctions = this._schemaFunctions || new chorus.collections.SchemaFunctionSet([], {
            id: this.get("id"),
            schemaName: this.get("name")
        });
        return this._schemaFunctions;
    },

    datasets: function() {
        if(!this._datasets) {
            this._datasets = new chorus.collections.DatasetSet([], { schemaId: this.id });
        }
        return this._datasets;
    },

    database: function() {
        var database = this._database || new chorus.models.Database(this.get("database"));
        if(this.loaded) {
            this._database = database;
        }
        return database;
    },

    instance: function() {
        var instance = this._instance;
        if(!this._instance) {
            if(this.has('instance')) {
                instance = new chorus.models.DynamicInstance(this.get('instance'));
            } else {
                instance = this.database().instance();
            }
        }
        if(this.loaded) {
            this._instance = instance;
        }
        return instance;
    },

    canonicalName: function() {
        return _.compact([this.instance().name(), this.database().name(), this.name()]).join(".");
    },

    isEqualToSchema: function(other) {
        return this.get("id") === other.get("id");
    }
}, {
    DEFAULT_NAME: "public"
});
