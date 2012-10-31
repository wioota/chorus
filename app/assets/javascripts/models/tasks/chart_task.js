chorus.models.ChartTask = chorus.models.Task.extend({
    constructorName: "ChartTask",
    urlTemplateBase: 'datasets/{{datasetId}}/visualizations',

    name: function() {
        return t("dataset.visualization.data.filename");
    },

    initialize: function(attrs) {
        this._super("initialize", arguments);
        this.dataset = this.get('dataset');
        this.unset("dataset");

        if (this.dataset) {
            this.set({ datasetId: this.dataset.get("id") }, {silent: true});
        }
        this.set({ "type": this.chartType });
    },

    getColumnLabel: function(columnName) {
        return this.columnLabels[columnName] ? t(this.columnLabels[columnName]) : columnName;
    }
});
