chorus.models.OracleDataSource = chorus.models.DataSource.extend({
    constructorName: "OracleDataSource",
    urlTemplate: "data_sources/{{id}}",
    nameAttribute: 'name',
    entityType: "oracle_data_source",

    showUrlTemplate: "data_sources/{{id}}/schemas",

    parameterWrapper: "data_source",

    defaults: {
        entityType: 'oracle_data_source'
    },

    attrToLabel: {
        "dbUsername": "instances.dialog.database_account",
        "dbPassword": "instances.dialog.database_password",
        "name": "instances.dialog.instance_name",
        "host": "instances.dialog.host",
        "port": "instances.dialog.port",
        "dbName": "instances.dialog.database_name",
        "description": "instances.dialog.description"
    },

    schemas: function(){
        var collection = new chorus.collections.SchemaSet();
        collection.urlTemplate = "data_sources/"+this.get("id")+"/schemas";
        return collection;
    }
});
