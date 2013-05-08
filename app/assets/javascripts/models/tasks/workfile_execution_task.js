chorus.models.WorkfileExecutionTask = chorus.models.Task.extend({
    urlTemplateBase: "workfiles/{{workfile.id}}/executions",
    constructorName: "",
    paramsToSave: ['checkId', 'sql'],

    name: function() {
        return this.get("workfile").get("fileName");
    },

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
