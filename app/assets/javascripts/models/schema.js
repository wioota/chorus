chorus.models.Schema = chorus.models.Base.include(
    chorus.Mixins.DataSourceCredentials.model
).extend({
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
            this._datasets = new chorus.collections.SchemaDatasetSet([], { schemaId: this.id });
        }
        return this._datasets;
    },

    tables: function() {
        if(!this._tables) {
            this._tables = new chorus.collections.SchemaDatasetSet([], {schemaId: this.id, tablesOnly: "true"});
        }
        return this._tables;
    },

    database: function() {
        var database = this._database || (this.get("database") && new chorus.models.Database(this.get("database")));
        if(this.loaded) {
            this._database = database;
        }
        return database;
    },

    dataSource: function() {
        var instance = this._instance;
        if(!this._instance) {
            if(this.has('instance')) {
                instance = new chorus.models.DynamicInstance(this.get('instance'));
            } else {
                instance = this.database().dataSource();
            }
        }
        if(this.loaded) {
            this._instance = instance;
        }
        return instance;
    },

    canonicalName: function() {
        return _.compact([this.dataSource().name(), this.database() && this.database().name(), this.name()]).join(".");
    },

    isEqualToSchema: function(other) {
        return this.get("id") === other.get("id");
    }
}, {
    DEFAULT_NAME: "public"
});
