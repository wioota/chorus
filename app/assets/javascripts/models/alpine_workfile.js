//= require ./workfile
chorus.models.AlpineWorkfile = chorus.models.Workfile.include(
    chorus.Mixins.DataSourceCredentials.model
).extend({
    constructorName: "AlpineWorkfile",
    parameterWrapper: "workfile",

    defaults: {
        entitySubtype: "alpine"
    },

    dataSourceRequiringCredentials: function() {
        if (this.serverErrors.modelData.entityType !== "workspace") {
            return this._super('dataSourceRequiringCredentials');
        }
    },

    showUrlTemplate: function(options) {
        if (options && options.workFlow) {
            return "work_flows/{{id}}";
        }

        return this._super("showUrlTemplate", arguments);
    },

    iconUrl: function(options) {
        return chorus.urlHelpers.fileIconUrl('afm', options && options.size);
    },

    iframeUrl: function() {
        var executionLocations = this.get('executionLocations');
        var uri = this.alpineUrlBase();
        var queryParams = {
            file_name: this.get("fileName"),
            workfile_id: this.id,
            session_id: chorus.session.get("sessionId"),
            method: "chorusEntry"
        };

        var databases = [];
        var hadoops = [];
        var oracles = [];
        _.each(executionLocations, function (location) {
            if(location.entityType === 'hdfs_data_source') {
                hadoops.push(location.id);
            } else if (location.entityType === 'gpdb_database') {
                databases.push(location.id);
            } else if (location.entityType === 'oracle_data_source') {
                oracles.push(location.id);
            }
        });

        if (hadoops.length > 0) {
            queryParams["hdfs_data_source_id[]"] = hadoops;
            if(this.get("hdfsDatasetIds")) queryParams["hdfs_dataset_id[]"] = this.get("hdfsDatasetIds");
        }

        if (databases.length > 0) {
            queryParams["database_id[]"] = databases;
            if (this.get("datasetIds")) queryParams["dataset_id[]"] = this.get("datasetIds");
        }

        if (oracles.length > 0) {
            queryParams["oracle_data_source_id[]"] = oracles;
            if (this.get("oracleDatasetIds")) queryParams["oracle_dataset_id[]"] = this.get("oracleDatasetIds");
        }

        uri.addQuery(queryParams);

        return uri.toString();
    },

    imageUrl: function() {
        var uri = this.alpineUrlBase();
        uri.addQuery({
            method: "chorusImage",
            workfile_id: this.id,
            session_id: chorus.session.get('sessionId')
        });
        return uri.toString();
    },

    alpineUrlBase: function() {
        var uri = URI({
            hostname: chorus.models.Config.instance().get('workflowUrl'),
            path: "/alpinedatalabs/main/chorus.do"
        });
        return uri;
    },

    isAlpine: function() {
        return true;
    },

    canOpen: function canOpen() {
        return this.workspace().currentUserCanCreateWorkFlows();
    },

    workFlowShowUrl: function() {
        return "#/work_flows/" + this.id;
    },

    executionLocations: function () {
        return _.map(this.get('executionLocations'), function (executionLocation) {
            return new chorus.models.DynamicExecutionLocation(executionLocation);
        }, this);
    },

    checkForHawq: function() {
        _.every(this.executionLocations(), function(el) {
            if(el.get('entityType') === 'gpdb_database' && el.dataSource().get('isHawq')) {
                chorus.toast("work_flows.toast.hawq");
                return false;
            }
            return true;
        });
    },

    run: function () {
        this.save({action: "run"});
    },

    stop: function () {
        this.save({action: "stop"});
    }
});