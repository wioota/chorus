chorus.models.GpdbInstance = chorus.models.DataSource.extend({
    constructorName: "GpdbInstance",
    urlTemplate: "data_sources/{{id}}",
    nameAttribute: 'name',
    entityType: "gpdb_instance",

    showUrlTemplate: "data_sources/{{id}}/databases",

    parameterWrapper: "data_source",

    defaults: {
        entityType: 'gpdb_instance'
    },

    declareValidations: function(newAttrs) {
        this.require("name", newAttrs);
        this.requirePattern("name", chorus.ValidationRegexes.MaxLength64(), newAttrs);

        this.require("host", newAttrs);
        this.require("port", newAttrs);
        this.require("dbName", newAttrs);
        this.requirePattern("port", chorus.ValidationRegexes.OnlyDigits(), newAttrs);
        if(this.isNew()) {
            this.require("dbUsername", newAttrs);
            this.require("dbPassword", newAttrs);
        }
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
