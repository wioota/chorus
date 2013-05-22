//= require ./workfile
chorus.models.AlpineWorkfile = chorus.models.Workfile.extend({
    constructorName: "AlpineWorkfile",
    parameterWrapper: "workfile",

    defaults: {
        entitySubtype: "alpine"
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
            database_id: this.get("databaseId"),
            file_name: this.get("fileName"),
            workfile_id: this.id,
            session_id: chorus.session.get("sessionId"),
            method: "chorusEntry"
        });

        return uri.toString();
    },

    imageUrl: function() {
        var uri = this.alpineUrlBase();
        uri.addQuery({
            method: "getWorkFlowImage"
        });
        return uri.toString();
    },

    runUrl: function() {
        var uri = this.alpineUrlBase();
        uri.addQuery({
            method: "runWorkFlow",
            chorus_workfile_type: "Workfile",
            chorus_workfile_id: this.id,
            chorus_workfile_name: this.get("fileName")
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
    }
});