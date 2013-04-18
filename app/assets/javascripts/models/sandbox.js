chorus.models.Sandbox = chorus.models.Base.extend({
    constructorName: "Sandbox",
    attrToLabel: {
        "dataSourceName": "instances.dialog.instance_name",
        "databaseName": "instances.dialog.database_name",
        "schemaName": "instances.dialog.schema_name"
    },

    urlTemplate: "workspaces/{{workspaceId}}/sandbox",

    declareValidations: function(attrs) {
        var missingDb = !this.get('databaseId') && !attrs["databaseId"];
        var missingSchema = !this.get('schemaId') && !attrs["schemaId"];
        if(missingSchema || missingDb) {
            this.require("schemaName", attrs);
            this.requirePattern("schemaName", chorus.ValidationRegexes.PostgresIdentifier(63), attrs);
        }
        if(missingDb) {
            this.require("databaseName", attrs);
            this.requirePattern("databaseName", chorus.ValidationRegexes.PostgresIdentifier(63), attrs);
        }
    },

    dataSource: function() {
        this._instance = this._instance || this.database().dataSource();
        return this._instance;
    },

    database: function() {
        this._database = this._database || this.schema().database();

        return this._database;
    },

    schema: function() {
        this._schema = this._schema || new chorus.models.Schema(this.attributes);

        return this._schema;
    },

    canonicalName: function() {
        return this.schema().canonicalName();
    }
});
