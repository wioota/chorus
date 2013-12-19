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
        var uri = this.alpineUrlBase();
        var queryParams = {
            workfile_id: this.id,
            session_id: chorus.session.get("sessionId"),
            method: "chorusEntry"
        };

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
        return URI({ path: "/alpinedatalabs/main/chorus.do" });
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