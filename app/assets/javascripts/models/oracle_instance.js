chorus.models.OracleInstance = chorus.models.Instance.extend({
    constructorName: "OracleInstance",
    urlTemplate: "oracle_instances/{{id}}",
    nameAttribute: 'name',
    entityType: "oracle_instance",

    showUrlTemplate: "instances/{{id}}/schemas",

    parameterWrapper: "oracle_instance",

    declareValidations: function(newAttrs) {
        this.require("name", newAttrs);
        this.requirePattern("name", chorus.ValidationRegexes.MaxLength64(), newAttrs);

        this.require("host", newAttrs);
        this.require("port", newAttrs);
        this.require("dbName", newAttrs);
        this.requirePattern("port", chorus.ValidationRegexes.OnlyDigits(), newAttrs);
        if (this.isNew()) {
            this.require("dbUsername", newAttrs);
            this.require("dbPassword", newAttrs);
        }
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

    providerIconUrl: function() {
        return this._imagePrefix + "icon_datasource_oracle.png";
    }
});
