chorus.views.NewTableImportDataGrid = chorus.views.ImportDataGrid.extend({
    constructorName: "NewTableImportDataGrid",
    headerRowHeight: 16,

    customizeHeaderRows: function(columns, columnNames) {
        this.addNameInputsToTopRow(columnNames);
        this.setupDataTypeMenus(columns);
    },

    addNameInputsToTopRow: function(columnNames) {
        _.each(this.$(".slick-header-column"), function (column, index) {
            var $name = $(column).find(".slick-column-name");
            $name.html("<input value='" + columnNames[index] + "'></input>");
        }, this);
    },

    setupDataTypeMenus: function(columns) {
        this.linkMenus = _.map(columns, function(item) {
            return new chorus.views.LinkMenu({
                options: [
                    {data: "integer", text: "integer"},
                    {data: "float", text: "float"},
                    {data: "text", text: "text"},
                    {data: "date", text: "date"},
                    {data: "time", text: "time"},
                    {data: "timestamp", text: "timestamp"}
                ],
                title: '',
                event: "setType",
                chosen: item.type
            });
        });

        var $dataTypes = this.$(".slick-headerrow-columns");
        _.each(this.linkMenus, function(linkMenu, index) {
            var $column = $dataTypes.find(".slick-headerrow-column").eq(index);
            $column.append('<div class="arrow"></div>');
            $column.append(linkMenu.render().el);
            $column.addClass("type");
            $column.addClass(linkMenu.options.chosen);
        });
    }
});