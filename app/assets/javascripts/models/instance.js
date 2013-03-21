chorus.models.Instance = chorus.models.Base.extend({
    constructorName: 'AbstractInstance',
    _imagePrefix: "/images/data_sources/",

    providerIconUrl: function() {
        return this._imagePrefix + 'icon_' + this.get('entityType') + '.png';
    },

    iconUrl: function () {
      return this.providerIconUrl();
    },

    eventType: function() {
        return "data_source";
    },

    isOnline: function() {
        return this.get("online");
    },

    isOffline: function() {
        return !this.isOnline();
    },

    stateText: function() {
        return t("instances.state." + (this.isOnline() ? 'online' : 'offline'));
    },

    version: function() {
        return this.get("version");
    },

    stateIconUrl: function() {
        var filename = this.isOnline() ? 'green.png' : 'yellow.png';
        return this._imagePrefix + filename;
    },

    owner: function() {
        return new chorus.models.User(
            this.get("owner")
        );
    },

    isOwner: function(user) {
        return this.owner().get("id") === user.get('id') && user instanceof chorus.models.User;
    },

    isGreenplum: function() {
        return false;
    },

    isHadoop: function() {
        return false;
    },

    isGnip: function() {
        return false;
    },

    isOracle: function() {
        return false;
    },

    canHaveIndividualAccounts: function() {
        return false;
    },

    accountForCurrentUser: function() {
        return null;
    },

    accounts: function() {
        return [];
    },

    usage: function() {
        return false;
    }
});
