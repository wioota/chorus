chorus.views.DataGrid = chorus.views.Base.extend({
    templateName: "data_grid",
    constructorName: "DataGrid",
    events: { "click .slick-cell": "selectCell" },

    postRender: function() {
        var columns = _.map(this.model.getColumns(), function(column, index) {
            return {name: column.name, field: index, id: column.name + index, sortable: true};
        });
        this.rows = this.model.getRows();
        var options = {
            defaultFormatter: this.cellFormatter,
            enableColumnReorder: false,
            enableTextSelectionOnCells: true,
            syncColumnCellResize: true,
            enableCellNavigation: true
        };

        this.grid && this.grid.destroy();
        this.grid = new Slick.Grid(this.$(".grid"), this.rows, columns, options);
        this.grid.onSort.subscribe(_.bind(this.sortFunction, this));
    },

    resizeGridToResultsConsole: function() {
        this.grid.resizeCanvas();
        this.grid.invalidate();
    },

    cellFormatter: function(row, cell, value, columnDef, dataContext){
        if (!value) { return value; }

        return "<span title='"+value+"'>"+value+"</span>";
    },

    selectCell: function(e) {
        if (window.getSelection && document.createRange) {
            var sel = window.getSelection();
            var range = document.createRange();
            range.selectNodeContents(e.currentTarget);
            sel.removeAllRanges();
            sel.addRange(range);
        } else if (document.selection && document.body.createTextRange) {
            var textRange = document.body.createTextRange();
            textRange.moveToElementText(e.currentTarget);
            textRange.select();
        }
    },

    sortFunction: function(e, args){
        var field = args.sortCol.field;

        var sort = function(a, b){
            var result =
                a[field] > b[field] ? 1 :
                    a[field] < b[field] ? -1 :
                        0;

            return args.sortAsc ? result : -result;
        };

        this.rows.sort(sort);
        this.grid.invalidate();
    },

    teardown: function() {
        this.grid && this.grid.destroy();
        this._super("teardown");
    }
});