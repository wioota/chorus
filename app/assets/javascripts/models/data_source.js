//= require ./instance
chorus.models.DataSource = chorus.models.Instance.extend({
    constructorName: 'DataSource',

    urlTemplate: "data_sources/{{id}}",
    showUrlTemplate: 'instances/{{id}}/databases',
    entityType: "data_source",

    providerIconUrl: function() {
        return '/images/instances/icon_' + this.get('entityType') + '.png';
    }
});