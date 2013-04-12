chorus.models.GpdbDataSource = chorus.models.DataSource.extend({
    constructorName: "GpdbDataSource",
    urlTemplate: "data_sources/{{id}}",
    nameAttribute: 'name',
    entityType: "gpdb_data_source",

    showUrlTemplate: "data_sources/{{id}}/databases",

    parameterWrapper: "data_source",

    defaults: {
        entityType: 'gpdb_data_source'
    },

    databases: function() {
        this._databases || (this._databases = new chorus.collections.DatabaseSet([], {instanceId: this.get("id")}));
        return this._databases;
    },

    attrToLabel: {
        "dbUsername": "instances.dialog.database_account",
        "dbPassword": "instances.dialog.database_password",
        "name": "instances.dialog.instance_name",
        "host": "instances.dialog.host",
        "port": "instances.dialog.port",
        "databaseName": "instances.dialog.database_name",
        "dbName": "instances.dialog.db_name",
        "description": "instances.dialog.description"
    }
});
