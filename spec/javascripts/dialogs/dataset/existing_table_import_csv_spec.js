describe("chorus.dialogs.ExistingTableImportCSV", function() {
    beforeEach(function() {
        chorus.page = {};
        chorus.page.workspace = rspecFixtures.workspace({
            sandboxInfo: {
                name: "mySchema",
                database: { name: "myDatabase", dataSource: { name: "myDataSource" } }
            }
        });
        this.sandbox = chorus.page.workspace.sandbox();
        this.csvOptions = {
            tableName: 'existing_table',
            hasHeader: true,
            contents: [
                "COL1,col2, col3 ,col 4,Col_5",
                "val1.1,val1.2,val1.3,val1.4,val1.5",
                "val2.1,val2.2,val2.3,val2.4,val2.5",
                "val3.1,val3.2,val3.3,val3.4,val3.5",
                "val4.1,val4.2,val4.3,val4.4,val4.5"
            ]
        };

        this.model = new (chorus.models.Base.extend({
            constructorName: 'FakeModel',
            urlTemplate: "workspaces/{{workspaceId}}/existing_tables"
        }))();

        this.model.set({
            truncate: true,
            workspaceId: '123'
        }, { silent: true });

        this.dialog = new chorus.dialogs.ExistingTableImportCSV({model: this.model, csvOptions: this.csvOptions , datasetId: "dat-id"});
        this.columns = [
            {name: "col1", typeCategory: "WHOLE_NUMBER", ordinalPosition: "3"},
            {name: "col2", typeCategory: "STRING", ordinalPosition: "4"},
            {name: "col3", typeCategory: "WHOLE_NUMBER", ordinalPosition: "1"},
            {name: "col4", typeCategory: "WHOLE_NUMBER", ordinalPosition: "2"},
            {name: "col5", typeCategory: "WHOLE_NUMBER", ordinalPosition: "5"},
            {name: "col6", typeCategory: "WHOLE_NUMBER", ordinalPosition: "6"}
        ];
        this.dataset = rspecFixtures.workspaceDataset.datasetTable({
            id: "dat-id",
            workspace: {id: this.model.get("workspaceId")}
        });
        this.server.completeFetchFor(this.dataset);
        this.qtip = stubQtip();
        stubDefer();
        this.server.completeFetchFor(this.dialog.columnSet, this.columns);
    });

    it("has the title", function() {
        expect(this.dialog.$('h1')).toContainTranslation("dataset.import.table.title");
    });

    it("has an import button", function() {
        expect(this.dialog.$('button.submit')).toContainTranslation("dataset.import.table.submit");
    });

    it("has the import button disabled by default", function() {
        expect(this.dialog.$('button.submit')).toBeDisabled();
    });

    it("has comma as the default separator", function() {
        expect(this.dialog.$('input[name=delimiter]:checked').val()).toBe(',');
    });

    it("shows an error when the CSV doesn't parse correctly", function() {
        this.csvOptions.contents.push('"Has Spaces",2,3,4,5');
        this.dialog.$("input.delimiter[value=' ']").click();

        expect(this.model.serverErrors).toBeDefined();
        expect(this.dialog.$(".errors")).not.toBeEmpty();
    });

    describe("with an existing toTable that has a funny name", function() {
        beforeEach(function() {
            this.dialog.tableName = "!@#$%^&*()_+";
            this.dialog.$("a.automap").click();
            this.server.reset();
            this.dialog.$("button.submit").click();
        });

        it("still imports and passes client side validation", function() {
            expect(this.server.lastCreateFor(this.dialog.model).url.length).toBeGreaterThan(0);
        });
    });

    function hasRightSeparator(separator) {
        return function() {
            beforeEach(function() {
                this.csvOptions = {
                    contents: [
                        "COL1" + separator + "col2" + separator + "col3" + separator + "col_4" + separator + "Col_5",
                        "val1.1" + separator + "val1.2" + separator + "val1.3" + separator + "val1.4" + separator + "val1.5",
                        "val2.1" + separator + "val2.2" + separator + "val2.3" + separator + "val2.4" + separator + "val2.5",
                        "val3.1" + separator + "val3.2" + separator + "val3.3" + separator + "val3.4" + separator + "val3.5"
                    ],
                    tableName: 'existing_table'
                };

                this.dialog = new chorus.dialogs.ExistingTableImportCSV({model: this.model, csvOptions: this.csvOptions, datasetId: "dat-id"});
                this.server.completeFetchFor(this.dataset);
                this.dialog.render();

                this.dialog.$("input.delimiter[value='" + separator + "']").click();
            });

            it("has " + separator + " as separator", function() {
                expect(this.dialog.$('input.delimiter:checked').val()).toBe(separator);
            });

            it("reparses the file with " + separator + " as the separator", function() {
                expect(this.dialog.$(".import_data_grid .column_name").length).toEqual(5);
            });

            it("updates the total columns in the progress section", function() {
                expect(this.dialog.$(".progress")).toContainTranslation("dataset.import.table.progress", { count: 0, total: 5 });
            });
        };
    }

    describe("selecting the 'tab' separator", hasRightSeparator('\t'));
    describe("selecting the 'comma' separator", hasRightSeparator(','));
    describe("selecting the 'semicolon' separator", hasRightSeparator(';'));
    describe("selecting the 'space' separator", hasRightSeparator(' '));

    describe("changing the separator", function() {
        beforeEach(function() {
            expect(this.dialog.model.get("types").length).toBe(5);
            this.dialog.$("input.delimiter[value=';']").click();
        });

        it("recalculates the column types", function() {
            expect(this.dialog.model.get("types").length).toBe(1);
        });
    });

    describe("specifying a custom delimiter", function() {
        beforeEach(function() {
            this.otherField = this.dialog.$('input[name=custom_delimiter]');
        });

        it("is empty on loading", function() {
            expect(this.otherField.val()).toBe("");
        });

        it("checks the Other radio button", function() {
            this.otherField.val("X");
            this.otherField.trigger("keyup");
            expect(this.dialog.$('input.delimiter[type=radio]:checked').val()).toBe("other");
        });

        it("retains its value after re-render", function() {
            this.otherField.val("X");
            this.otherField.trigger("keyup");
            expect(this.otherField).toHaveValue("X");
        });

        describe("clicking on radio button Other", function() {
            beforeEach(function() {
                spyOn($.fn, 'focus');
                this.dialog.$("input#delimiter_other").click();
            });

            it("focuses the text field", function() {
                expect($.fn.focus).toHaveBeenCalled();
                expect($.fn.focus.mostRecentCall.object).toBe("input:text");
            });

            describe("entering 'z' as a separator", function() {
                beforeEach(function() {
                    this.csvOptions =  {
                        contents: [
                            "COL1zcol2zcol3zcol_4zCol_5",
                            "val1.1zval1.2zval1.3zval1.4zval1.5",
                            "val2.1zval2.2zval2.3zval2.4zval2.5",
                            "val3.1zval3.2zval3.3zval3.4zval3.5"
                        ],
                        tableName: "existing_table"
                    };


                    this.dialog = new chorus.dialogs.ExistingTableImportCSV({model: this.model, csvOptions: this.csvOptions, datasetId: "dat-id"});
                    this.server.completeFetchFor(this.dataset);
                    this.dialog.render();

                    this.dialog.$("input#delimiter_other").click();
                    this.dialog.$('input[name=custom_delimiter]').val("z");
                    this.dialog.$('input[name=custom_delimiter]').trigger('keyup');
                });

                it("has z as separator", function() {
                    expect(this.dialog.$('input.delimiter:checked').val()).toBe('other');
                });

                it("reparses the file with z as the separator", function() {
                    expect(this.dialog.$(".import_data_grid .column_name").length).toEqual(5);
                });
            });
        });
    });

    it("has instructions", function() {
        expect(this.dialog.$('.directions')).toContainTranslation("dataset.import.table.existing.directions",
            {
                toTable: "existing_table"
            });
    });

    it("has a progress tracker", function() {
        expect(this.dialog.$(".progress")).toContainTranslation("dataset.import.table.progress", {count: 0, total: 5});
    });

    it("has an auto-map link", function() {
        expect(this.dialog.$("a.automap")).toContainTranslation("dataset.import.table.automap");
    });

    describe("clicking the 'automap' link", function() {
        beforeEach(function() {
            this.dialog.$("a.automap").click();
        });

        it("selects destination columns in the dataset's DDL order", function() {
            var columnNameLinks = this.dialog.$(".column_mapping a");
            expect(columnNameLinks.eq(0)).toHaveText("col1");
            expect(columnNameLinks.eq(1)).toHaveText("col2");
            expect(columnNameLinks.eq(2)).toHaveText("col3");
            expect(columnNameLinks.eq(3)).toHaveText("col4");
            expect(columnNameLinks.eq(4)).toHaveText("col5");

            expect(columnNameLinks).not.toHaveClass("selection_conflict");
        });

        it("displays the correct progress text", function() {
            expect(this.dialog.$(".progress")).toContainTranslation("dataset.import.table.progress", {count: 5, total: 5});
        });
    });

    it("checks the include header row checkbox by default", function() {
        expect(this.dialog.$("#hasHeader")).toBeChecked();
    });

    describe("the data table", function() {
        it('shows a mapping selector for each of the columns in the csv', function(){
            var $columnMaps = this.dialog.$(".import_data_grid .column_mapping");
            expect($columnMaps.length).toEqual(5);

            _.each($columnMaps, function(el) {
                expect($(el).text()).toContainTranslation("dataset.import.table.existing.map_to");
                expect($(el).find("a").text()).toContainTranslation("dataset.import.table.existing.select_one");
                expect($(el).find("a")).toHaveClass("selection_conflict");
            });
        });

        it("converts the column names into db friendly format", function() {
            var $columnNames = this.dialog.$(".import_data_grid .column_name");
            expect($columnNames.eq(0).text()).toBe("col1");
            expect($columnNames.eq(1).text()).toBe("col2");
            expect($columnNames.eq(2).text()).toBe("col3");
            expect($columnNames.eq(3).text()).toBe("col_4");
            expect($columnNames.eq(4).text()).toBe("col_5");
        });

        it("has the right data in each cell", function() {
            $("#jasmine_content").append("<div class='foo'></div>");
            //If you assign the dialog element directly to #jasmine_content, the later teardown will destroy jasmine content
            this.dialog.setElement($("#jasmine_content .foo"));
            var grid = this.dialog.dataGrid;
            _.each(this.dialog.$(" .import_data_grid .column_name"), function(column, i) {
                var cells = _.map([0,1,2,4], function(j){
                    return grid.getCellNode(j, i);
                });

                expect(cells.length).toEqual(3);
                _.each(cells, function(cell, j) {
                    expect($(cell)).toContainText("val" + (j + 1) + "." + (i + 1));
                });
            });
        });

        describe("choosing the mapping for a column in the csv", function() {
            var menuLinks, menus;

            beforeEach(function() {
                menuLinks = this.dialog.$(".column_mapping a");
                menuLinks.click(); // just to initialize all qtips
                menus = this.qtip.find("ul");
            });

            it("shows the destination columns and their types", function() {
                expect(menus.eq(0).find("li").length).toBe(6);
                _.each(menus.eq(0).find("li"), function(li, i) {
                    var $li = $(li);
                    var type = chorus.models.DatabaseColumn.humanTypeMap[this.columns[i].typeCategory];
                    expect($li.find("a")).toContainText("col" + (i + 1));
                    expect($li.find(".type")).toContainText(type);
                }, this);
            });

            context("selecting a destination column", function() {
                beforeEach(function() {
                    menus.eq(0).find("li:eq(1) a").click();
                });

                function itSelectsDestinationColumn(sourceIndex, destinationIndex, destinationName, options) {
                    it("shows the right destination column as selected", function() {
                        expect(menuLinks.eq(sourceIndex)).toHaveText(destinationName);

                        var menu = menus.eq(sourceIndex);
                        expect(menu.find(".check").not(".hidden").length).toBe(1);
                        expect(menu.find(".name.selected").length).toBe(1);
                        var selectedLi = menu.find("li[name=" + destinationName + "]");
                        expect(selectedLi.find(".check")).not.toHaveClass("hidden");
                        expect(selectedLi.find(".name")).toHaveClass("selected");
                    });

                    if (options && options.conflict) {
                        it("marks that source column as having a selection conflict", function() {
                            expect(menuLinks.eq(sourceIndex)).not.toHaveClass("selected");
                            expect(menuLinks.eq(sourceIndex)).toHaveClass("selection_conflict");
                        });
                    } else {
                        it("marks that source column as having been mapped", function() {
                            expect(menuLinks.eq(sourceIndex)).toHaveClass("selected");
                            expect(menuLinks.eq(sourceIndex)).not.toHaveClass("selection_conflict");
                        });
                    }
                }

                function itHasSelectedCounts(counts) {
                    it("updates the counts in all of the menus", function() {
                        _.each(menus, function(menu) {
                            _.each($(menu).find(".count"), function(el, index) {
                                var count = counts[index];
                                if (count > 0) {
                                    expect($(el).text()).toContainText("(" + count + ")");
                                }
                            });
                        });
                    });
                }

                itSelectsDestinationColumn(0, 1, "col2");
                itHasSelectedCounts([0, 1, 0, 0, 0]);

                it("does not update the text of a different destination column link", function() {
                    expect(menuLinks.eq(1)).toContainTranslation("dataset.import.table.existing.select_one");
                    expect(menuLinks.eq(1)).not.toHaveClass("selected");
                    expect(menuLinks.eq(1)).toHaveClass("selection_conflict");
                });

                it("updates the progress tracker", function() {
                    expect(this.dialog.$(".progress")).toContainTranslation("dataset.import.table.progress", {count: 1, total: 5});
                });

                it("keeps the import button disabled", function() {
                    expect(this.dialog.$('button.submit')).toBeDisabled();
                });

                context("choosing the same destination column again", function() {
                    beforeEach(function() {
                        menus.eq(0).find("li:eq(1) a").click();
                    });

                    itSelectsDestinationColumn(0, 1, "col2");
                    itHasSelectedCounts([0, 1, 0, 0, 0]);

                    it("does not double-count the column", function() {
                        expect(menus.eq(0).find("li:eq(1) .count")).toContainText("(1)");
                        expect(this.dialog.$(".progress")).toContainTranslation("dataset.import.table.progress", {count: 1, total: 5});
                    });
                });

                context("when choosing a different destination column for the same source column", function() {
                    beforeEach(function() {
                        menus.eq(0).find("li:eq(2) a").click();
                    });

                    itSelectsDestinationColumn(0, 2, "col3");
                    itHasSelectedCounts([0, 0, 1, 0, 0]);
                });

                context("when mapping another source column to the same destination column", function() {
                    beforeEach(function() {
                        menus.eq(1).find("li:eq(1) a").click();
                    });

                    itSelectsDestinationColumn(0, 1, "col2", { conflict: true });
                    itSelectsDestinationColumn(1, 1, "col2", { conflict: true });
                    itHasSelectedCounts([0, 2, 0, 0, 0]);

                    it("updates the progress tracker", function() {
                        expect(this.dialog.$(".progress")).toContainTranslation("dataset.import.table.progress", {count: 2, total: 5});
                    });
                });

                context("when all source columns but one are mapped", function() {
                    beforeEach(function() {
                        for (var i = 0; i < 4; i++) {
                            menus.eq(i).find("li a").eq(i).click();
                        }
                    });

                    itHasSelectedCounts([1, 1, 1, 1, 0]);

                    it("the last unselected column map is still displayed with red", function() {
                        expect(menuLinks.eq(0)).toHaveClass("selected");
                        expect(menuLinks.eq(1)).toHaveClass("selected");
                        expect(menuLinks.eq(2)).toHaveClass("selected");
                        expect(menuLinks.eq(3)).toHaveClass("selected");
                        expect(menuLinks.eq(4)).toHaveClass("selection_conflict");
                    });
                });
            });
        });
    });

    describe("unchecking the include header box", function() {
        beforeEach(function() {
            spyOn(this.dialog, "postRender").andCallThrough();
            spyOn(this.dialog, "recalculateScrolling").andCallThrough();
            this.dialog.$("#hasHeader").prop("checked", false).change();
        });

        it("sets header on the csv model", function() {
            expect(this.dialog.model.get("hasHeader")).toBeFalsy();
        });

        it("re-renders", function() {
            expect(this.dialog.postRender).toHaveBeenCalled();
        });

        it("the box is unchecked", function() {
            expect(this.dialog.$("#hasHeader").prop("checked")).toBeFalsy();
        });

        describe("rechecking the box", function() {
            beforeEach(function() {
                this.dialog.postRender.reset();
                this.dialog.$("#hasHeader").prop("checked", true);
                this.dialog.$("#hasHeader").change();
            });
            it("sets header on the csv model", function() {
                expect(this.dialog.model.get("hasHeader")).toBeTruthy();
            });
            it("re-renders", function() {
                expect(this.dialog.postRender).toHaveBeenCalled();
            });
            it("the box is checked", function() {
                expect(this.dialog.$("#hasHeader").prop("checked")).toBeTruthy();
            });
        });
    });

    describe("when all columns have been mapped", function() {
        beforeEach(function() {
            spyOn(this.dialog, "closeModal");
            this.expectedColumnNames = [];
            for (var i = 0; i < 5; i++) {
                this.dialog.$(".column_mapping a:eq(" + i + ")").click();
                this.qtip.find(".qtip:last .ui-tooltip-content li:eq(" + (i) + ") a").click();
                this.expectedColumnNames.push(this.columns[i].name);
            }
        });

        it("enables the import button", function() {
            expect(this.dialog.$('button.submit')).toBeEnabled();
        });

        context("clicking import button with invalid fields", function() {
            beforeEach(function() {
                spyOn(this.dialog.model, "performValidation").andReturn(false);
                this.dialog.$("button.submit").click();
            });

            it("re-enables the submit button", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
                expect(this.dialog.$("button.submit").text().trim()).toMatchTranslation("dataset.import.table.submit");
            });
        });

        describe("clicking the import button", function() {
            beforeEach(function() {
                this.dialog.$("button.submit").click();
            });

            it("starts the spinner", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
                expect(this.dialog.$("button.submit").text().trim()).toMatchTranslation("dataset.import.importing");
            });

            it("imports the file", function() {
                expect(this.server.lastCreate().url).toBe(this.dialog.model.url());
                var params = this.server.lastCreate().params();
                expect(params["fake_model[file_name]"]).toBe(this.dialog.model.get("fileName"));
                expect(params["fake_model[table_name]"]).toBe("existing_table");
                expect(params["fake_model[delimiter]"]).toBe(",");
                expect(params["fake_model[type]"]).toBe("existingTable");
                expect(params["fake_model[has_header]"]).toBe('true');
                expect(params["fake_model[truncate]"]).toBe('true');
                expect(params["fake_model[column_names][]"]).toEqual(this.expectedColumnNames);
            });

            context("when the post to import responds with success", function() {
                beforeEach(function() {
                    spyOn(chorus, 'toast');
                    spyOn(chorus.router, "navigate");
                    spyOn(chorus.PageEvents, 'trigger');
                    this.server.lastCreateFor(this.dialog.model).succeed();
                });

                it("closes the dialog and displays a toast", function() {
                    expect(this.dialog.closeModal).toHaveBeenCalled();
                    expect(chorus.toast).toHaveBeenCalledWith("dataset.import.started");
                });

                it("triggers csv_import:started", function() {
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("csv_import:started");
                });

                it("should navigate to the destination sandbox table", function() {
                    expect(chorus.router.navigate).toHaveBeenCalledWith(this.dialog.dataset.showUrl());
                });
            });

            context("when the import fails", function() {
                beforeEach(function() {
                    this.server.lastCreateFor(this.dialog.model).failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
                });

                it("displays the error", function() {
                    expect(this.dialog.$(".errors")).toContainText("A can't be blank");
                });

                it("re-enables the submit button", function() {
                    expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
                });
            });
        });

        describe("and then double mapping a destination column", function() {
            beforeEach(function() {
                this.dialog.$(".column_mapping:eq(0)").click();
                this.qtip.find(".qtip:last .ui-tooltip-content li:eq(1) a").click();
            });
            it("disables the import button", function() {
                expect(this.dialog.$('button.submit')).toBeDisabled();
            });
        });
    });

    describe("more source columns than destination columns", function() {
        context("when there are no destination columns", function() {
            beforeEach(function() {
                this.csvOptions = {
                    contents: ["a,b,c,d"],
                    tableName: 'existing_table'
                };

                this.dialog = new chorus.dialogs.ExistingTableImportCSV({model: this.model, csvOptions: this.csvOptions, datasetId: "dat-id"});
                this.server.completeFetchFor(this.dialog.dataset);
                this.server.completeFetchFor(this.dialog.columnSet);
            });

            it("displays the error message", function() {
                expect(this.dialog.$(".errors").text()).toContainTranslation("field_error.source_columns.LESS_THAN_OR_EQUAL_TO");
            });
        });

        context("when there are fewer destination columns", function() {
            beforeEach(function() {
                this.csvOptions = {
                    contents: [ "e,f,g" ],
                    tableName: 'existing_table'
                };

                this.dialog = new chorus.dialogs.ExistingTableImportCSV({model: this.model, csvOptions: this.csvOptions, datasetId: "dat-id"});
                this.server.completeFetchFor(this.dialog.dataset);
                this.columns = [
                    {name: "a", typeCategory: "WHOLE_NUMBER"}
                ];
                this.server.completeFetchFor(this.dialog.columnSet, this.columns);
            });

            it("displays error message", function() {
                expect(this.dialog.$(".errors").text()).toContainTranslation("field_error.source_columns.LESS_THAN_OR_EQUAL_TO");
            });

            context("and then selecting a column", function() {
                beforeEach(function() {
                    this.dialog.$(".column_mapping:eq(1)").click();
                    this.qtip.find(".qtip:eq(0) .ui-tooltip-content li:eq(1) a").click();
                });

                it("still shows the errors", function() {
                    expect(this.dialog.$(".errors").text()).toContainTranslation("field_error.source_columns.LESS_THAN_OR_EQUAL_TO");
                });
            });

            context("and then changing the delimiter", function() {
                beforeEach(function() {
                    this.dialog.$("input.delimiter[value=';']").click();
                });

                it("should clear the error message", function() {
                    expect(this.dialog.$(".errors").text()).toBe("");
                });
            });
        });
    });
});
