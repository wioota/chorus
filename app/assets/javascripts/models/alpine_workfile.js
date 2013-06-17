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
        uri.addQuery({
            database_id: this.get("executionLocation").id,
            file_name: this.get("fileName"),
            workfile_id: this.id,
            session_id: chorus.session.get("sessionId"),
            method: "chorusEntry",
            "dataset_id[]": this.get("datasetIds")
        });

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
            hostname: chorus.models.Config.instance().get('workFlowUrl'),
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

    executionLocation: function() {
        return this.get('executionLocation');
    }
});