chorus.models.DataPreviewTask = chorus.models.Task.extend({
    nameAttribute: "objectName",

    urlTemplateBase: "datasets/{{dataset.id}}/previews",

    getRows: function() {
        var rows = this.get("rows"),
            columns = this.getColumns(),
            column,
            value;
        return _.map(rows, function(row) {
            return _.inject(_.zip(columns, row), function(memo, columnValuePair) {
                column = columnValuePair[0];
                value = columnValuePair[1];
                memo[column.uniqueName] = value;
                return memo;
            }, {});
        });
    }
});

