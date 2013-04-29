chorus.views.DataTable = chorus.views.Base.extend({
    templateName: "data_table",
    constructorName: "DataTable",

    postRender: function() {
        var columns = _.map(this.model.getColumns(), function(column) {
            return {name: column.name, field: column.name, id: column.name };
        });
        var rows = this.model.getSortedRows(this.model.getRows());
        var options = {
            enableColumnReorder: false,
            enableTextSelectionOnCells: true,
            syncColumnCellResize: true
        };

        this.grid = new Slick.Grid(this.$(".data_grid"), rows, columns, options);
    },

    resizeGridToResultsConsole: function() {
        this.grid.resizeCanvas();
        this.grid.invalidate();
    }
});