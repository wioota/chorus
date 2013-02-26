chorus.models.GnipInstance = chorus.models.Instance.extend({
    constructorName: "GnipInstance",
    urlTemplate: "gnip_instances/{{id}}",
    showUrlTemplate: "gnip_instances/{{id}}",
    shared: true,
    entityType: "gnip_instance",
    parameterWrapper: "gnip_instance",

    isShared: function() {
        return true;
    },

    isGnip: function() {
        return true;
    },

    stateText: function() {
        return 'Online';
    },

    stateIconUrl: function() {
        return this._imagePrefix + 'green.png';
    },

    declareValidations: function(newAttrs) {
        this.require("name", newAttrs);
        this.requirePattern("name", chorus.ValidationRegexes.MaxLength64(), newAttrs);
        this.require("streamUrl", newAttrs);
        this.require("username", newAttrs);

        if (!this.get('id')) {
            this.require("password", newAttrs);
        }
    },

    sharedAccountDetails: function() {
        return this.get("username");
    }

});
