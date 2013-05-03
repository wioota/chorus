chorus.views.DataTable = chorus.views.Base.extend({
    templateName: "data_table",
    constructorName: "DataTable",

    postRender: function() {
        var columns = _.map(this.model.getColumns(), function(column, index) {
            return {name: column.name, field: index };
        });
        var rows = this.model.getRows();
        var options = {
            defaultFormatter: this.cellFormatter,
            enableColumnReorder: false,
            enableTextSelectionOnCells: true,
            syncColumnCellResize: true
        };

        this.grid = new Slick.Grid(this.$(".data_grid"), rows, columns, options);
    },

    resizeGridToResultsConsole: function() {
        this.grid.resizeCanvas();
        this.grid.invalidate();
    },

    cellFormatter: function(row, cell, value, columnDef, dataContext){
        if (!value) { return value; }

        return "<span title='"+value+"'>"+value+"</span>";
    }
});