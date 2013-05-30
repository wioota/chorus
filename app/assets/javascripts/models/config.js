chorus.models.Config = chorus.models.Base.extend({
    constructorName: "Config",
    urlTemplate:"config/",

    isExternalAuth: function() {
        return this.get("externalAuthEnabled");
    },

    fileSizeMbWorkfiles: function() {
        return this.get("fileSizesMbWorkfiles");
    },

    fileSizeMbCsvImports: function() {
        return this.get("fileSizesMbCsvImports");
    }
 }, {
    instance:function () {
        if (!this._instance) {
            this._instance = new chorus.models.Config();
        }

        return this._instance;
    }
});
