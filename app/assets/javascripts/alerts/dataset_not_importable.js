chorus.alerts.DatasetNotImportable = chorus.alerts.Base.extend({
    constructorName: "DatasetNotImportable",
    additionalClass:"error",

    preRender: function() {
        var invalidColumns = this.options.datasetImportability.get('invalidColumns'),
            supportedDatatypes = this.options.datasetImportability.get('supportedDatatypes');

        this.title = t('dataset.import.not_importable.title');
        this.body = this.bodyContent(invalidColumns, supportedDatatypes);
    },

    postRender: function() {
        this.$("button.submit").addClass("hidden");
    },

    bodyContent: function(invalidColumns, supportedDatatypes) {
        return Handlebars.helpers.renderTemplate("dataset_not_importable_body", {
            invalidColumns: invalidColumns,
            supportedDatatypes: supportedDatatypes
        });
    }
});
