chorus.models.DataSource = chorus.models.Base.extend({
    constructorName: 'DataSource',

    showUrlTemplate: 'data_sources/{{id}}/databases',

    providerIconUrl: function() {
        return '/images/instances/icon_' + this.get('entityType') + '.png';
    }
});