//= require ./workfile
chorus.models.AlpineWorkfile = chorus.models.Workfile.extend({
    constructorName: "AlpineWorkfile",

    iconUrl: function(options) {
        return chorus.urlHelpers.fileIconUrl('afm', options && options.size);
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
            chorus_workfile_id: this.id
        });
        return uri.toString();
    },

    alpineUrlBase: function() {
        var uri = URI({
            protocol: "http",
            hostname: chorus.models.Config.instance().get('alpineUrl'),
            port: chorus.models.Config.instance().get('alpinePort'),
            path: "/alpinedatalabs/main/chorus.do"
        });
        uri.addQuery({
            api_key: chorus.models.Config.instance().get('alpineApiKey'),
            id: this.get("alpineId")
        });
        return uri;
    },

    isAlpine: function() {
        return true;
    }
});