chorus.views.ExistingTableImportDataGrid = chorus.views.ImportDataGrid.extend({
    constructorName: "ExistingTableImportDataGrid",
    headerRowHeight: 32,

    customizeHeaderRows: function(columns, columnNames) {
        var $mappings = this.$(".slick-headerrow-column");
        $mappings.addClass("column_mapping");
        $mappings.append("<span>"+t('dataset.import.table.existing.map_to')+"</span>");

        $mappings.append('<a href="#" class="selection_conflict"></a>');
        $mappings.find("a").append(
            '<span class="destination_column_name">' +
                t('dataset.import.table.existing.select_one') +
            '</span><span class="arrow"/>');
    }
});