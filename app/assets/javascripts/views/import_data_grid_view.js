chorus.views.ImportDataGrid = chorus.views.Base.extend({
    templateName: "no_template",
    constructorName: "ImportDataGrid",
    additionalClass: "import_data_grid",
    headerRowHeight: 0,
    customizeHeaderRows: $.noop,

    initializeDataGrid: function(columns, rows, columnNames) {
        var gridCompatibleRows = this.convert2DArrayToArrayOfHashTables(rows);
        var gridCompatibleColumnCells = _.map(columns, function (column, index) {
            return {
                name: column.name,
                field: index.toString(),
                id: index.toString(),
                minWidth: 100
            };
        });

        var options = {
            enableColumnReorder: false,
            enableTextSelectionOnCells: true,
            syncColumnCellResize: true,
            showHeaderRow: true,
            headerRowHeight: this.headerRowHeight,
            defaultColumnWidth: 130
        };

        this.slickGrid = new Slick.Grid(this.$el, gridCompatibleRows, gridCompatibleColumnCells, options);
        this.scrollHeaderRow();
        this.customizeHeaderRows(columns, columnNames);
        this.$(".slick-column-name").addClass("column_name");

        _.defer(_.bind(function () {
            this.slickGrid.resizeCanvas();
            this.slickGrid.invalidate();
        }, this));
    },

    scrollHeaderRow: function() {
        this.slickGrid.onScroll.subscribe(_.bind(function (e, args) {
            this.$('.slick-headerrow-columns').css({left: -args.scrollLeft});
        }, this));
    },

    convert2DArrayToArrayOfHashTables: function(rows) {
        return _.map(rows, function (row) {
            return _.reduce(row, function (memo, cell, index) {
                memo[index.toString()] = cell;
                return memo;
            }, {});
        });
    }
});