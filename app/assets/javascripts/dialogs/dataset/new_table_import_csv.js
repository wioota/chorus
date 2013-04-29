chorus.dialogs.NewTableImportCSV = chorus.dialogs.Base.extend({
    constructorName: "NewTableImportCSV",

    templateName: "new_table_import_csv",
    additionalClass: "table_import_csv dialog_wide",
    title: t("dataset.import.table.title"),
    ok: t("dataset.import.table.submit"),
    loadingKey: "dataset.import.importing",
    includeHeader: true,

    delimiter: ',',

    events: {
        "click button.submit": "startImport",
        "change #hasHeader": "setHeader",
        "keyup input.delimiter[name=custom_delimiter]": "setOtherDelimiter",
        "paste input.delimiter[name=custom_delimiter]": "setOtherDelimiter",
        "click input.delimiter[type=radio]": "setDelimiter",
        "click input#delimiter_other": "focusOtherInputField"
    },

    setup: function() {
        this.csvOptions = this.options.csvOptions;
        this.model = this.options.model;
        this.contents = this.csvOptions.contents;

        this.model.set({
            hasHeader: this.csvOptions.hasHeader,
            tableName: chorus.utilities.CsvParser.normalizeForDatabase(this.csvOptions.tableName)
        });

        this.subscribePageEvent("choice:setType", this.onSelectType);

        this.listenTo(this.model, "saved", this.saved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.listenTo(this.model, "validationFailed", this.saveFailed);
    },

    postRender: function() {
        var $dataTypes = this.$(".data_types");

        var csvParser = new chorus.utilities.CsvParser(this.contents, this.model.attributes);
        var columns = csvParser.getColumnOrientedData();
        var rows = csvParser.rows;
        this.model.serverErrors = csvParser.serverErrors;

        this.model.set({
            types: _.pluck(columns, "type")
        }, {silent: true});

        if (this.model.serverErrors) {
            this.showErrors();
        }

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
        _.each(this.linkMenus, function(linkMenu, index) {
            $dataTypes.find(".th").eq(index).find(".center").append(linkMenu.render().el);
        });

        this.$("input.delimiter").prop("checked", false);
        if (_.contains([",", "\t", ";", " "], this.delimiter)) {
            this.$("input.delimiter[value='" + this.delimiter + "']").prop("checked", true);
        } else {
            this.$("input#delimiter_other").prop("checked", true);
        }

        this.initializeDataGrid(columns, rows);
    },

    revealed: function() {
        var csvParser = new chorus.utilities.CsvParser(this.contents, this.model.attributes);
        var columns = csvParser.getColumnOrientedData();
        var rows = csvParser.rows;
        this.initializeDataGrid(columns, rows);
    },

    additionalContext: function() {
        var options = _.clone(this.model.attributes);
        options.columnNameOverrides = this.getColumnNames();
        return {
            includeHeader: this.includeHeader,
            columns: new chorus.utilities.CsvParser(this.contents, options).getColumnOrientedData(),
            delimiter: this.other_delimiter ? this.delimiter : '',
            directions: Handlebars.helpers.unsafeT("dataset.import.table.new.directions", {
                tablename_input_field: "<input type='text' name='tableName' value='" + this.model.get('tableName') + "'/>"
            }),
            ok: this.ok
        };
    },

    saved: function() {
        this.closeModal();
        chorus.toast("dataset.import.started");
        chorus.PageEvents.trigger("csv_import:started");
    },

    saveFailed: function() {
        this.$("button.submit").stopLoading();
    },

    onSelectType: function(data, linkMenu) {
        var $typeDiv = $(linkMenu.el).closest("div.type");
        $typeDiv.removeClass("integer float text date time timestamp").addClass(data);
    },

    storeColumnNames: function() {
        var $names = this.$(".column_names input:text");

        var columnNames;
        if ($names.length) {
            columnNames = _.map($names, function(name, i) {
                return $names.eq(i).val();
            });

            if (this.model.get("hasHeader")) {
                this.headerColumnNames = columnNames;
            } else {
                this.generatedColumnNames = columnNames;
            }
        }
    },

    storeColumnInfo: function() {
        this.storeColumnNames();

        var $types = this.$(".data_types .chosen");
        var types = _.map($types, function($type, i) {
            return $types.eq(i).text();
        });
        this.model.set({types: types}, {silent: true});
    },

    initializeDataGrid: function (columns, rows) {
        var gridCompatibleColumnCells = _.map(columns, function (column, index) {
            return {name: index.toString(), field: index.toString(), id: index.toString() };
        });
        var gridCompatibleRows = _.map(rows, function (row) {
            return _.reduce(row, function (memo, cell, index) {
                memo[index.toString()] = cell;
                return memo;
            }, {});
        });
        var options = {
            enableColumnReorder: false,
            enableTextSelectionOnCells: true,
            syncColumnCellResize: true,
            showHeaderRow: true
        };

        this.grid = new Slick.Grid(this.$(".data_grid"), gridCompatibleRows, gridCompatibleColumnCells, options);

        _.defer(_.bind(function () {
            this.grid.resizeCanvas();
            this.grid.invalidate();
        }, this));
    },

    getColumnNames: function() {
        return this.model.attributes.hasHeader ? this.headerColumnNames : this.generatedColumnNames;
    },

    startImport: function() {
        if (this.performValidation()) {
            this.storeColumnInfo();
            this.updateModel();

            this.$("button.submit").startLoading(this.loadingKey);
            this.model.save();
        }

        if (this.model.serverErrors) {
            this.showErrors();
        }
    },

    performValidation: function() {
        var $names = this.$(".column_names input:text");
        var pattern = chorus.ValidationRegexes.ChorusIdentifier64();
        var allValid = true;

        var $tableName = this.$(".directions input:text");

        this.clearErrors();

        if(!$tableName.val().match(pattern)) {
            allValid = false;
            this.markInputAsInvalid($tableName, t("import.validation.toTable.required"), true);
        }

        _.each($names, function(name, i) {
            var $name = $names.eq(i);
            if (!$name.val().match(pattern)) {
                allValid = false;
                this.markInputAsInvalid($name, t("import.validation.column_name"), true);
            }
        }, this);

        return allValid;
    },

    updateModel: function() {
        var newTableName = chorus.utilities.CsvParser.normalizeForDatabase(this.$(".directions input:text").val());
        this.model.set({
            hasHeader: !!(this.$("#hasHeader").prop("checked")),
            delimiter: this.delimiter,
            tableName: newTableName,
            toTable: newTableName,
            columnNames: this.getColumnNames()
        });
    },

    adjustHeaderPosition: function() {
        this.$(".thead").css({ "left": -this.scrollLeft() });
    },

    scrollLeft: function() {
        var api = this.$(".tbody").data("jsp");
        return api && api.getContentPositionX();
    },

    setDelimiter: function(e) {
        if (e.target.value === "other") {
            this.delimiter = this.$("input[name=custom_delimiter]").val();
            this.other_delimiter = true;
        } else {
            this.delimiter = e.target.value;
            this.other_delimiter = false;
        }
        this.updateModel();
    },

    setHeader: function() {
        this.storeColumnInfo();
        this.updateModel();

        this.render();
//        this.recalculateScrolling();
    },

    focusOtherInputField: function(e) {
        this.$("input[name=custom_delimiter]").focus();
    },

    setOtherDelimiter: function() {
        this.$("input.delimiter[type=radio]").prop("checked", false);
        var otherRadio = this.$("input#delimiter_other");
        otherRadio.prop("checked", true);
        otherRadio.click();
    }
});
