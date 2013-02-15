describe("chorus.views.DataTabDatasetColumnList", function() {
    describe("initialization", function() {
        context("when there is no sandbox", function() {
            beforeEach(function() {
                this.view = new chorus.views.DataTabDatasetColumnList({ sandbox: undefined });
            });

            it("should not crash", function() {
                expect(this.view).toBeDefined();
            });
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view = new chorus.views.DataTabDatasetColumnList({ sandbox: rspecFixtures.workspace().sandbox() });
            this.view.render();
        });

        it("should show a loading spinner", function() {
            expect(this.view.$(".loading_section")).toExist();
        });

        describe("when rendered with a databaseView", function() {
            beforeEach(function() {
                this.databaseView = rspecFixtures.dataset({ objectName: "brian_the_view", schema: {name: "john_the_schema"}, objectType: "VIEW" });
                chorus.PageEvents.broadcast("datasetSelected", this.databaseView);
                this.server.completeFetchAllFor(this.databaseView.columns(), [rspecFixtures.databaseColumn()]);
            });

            it("renders successfully", function() {
                expect(this.view.$('li')).toExist();
            });
        });

        describe("when rendered with a chorus view", function() {
            var chorusView;
            beforeEach(function() {
                chorusView = rspecFixtures.workspaceDataset.chorusView({ objectName: "tobias_the_chorus_view" });
                chorus.PageEvents.broadcast("datasetSelected", chorusView);
                this.server.completeFetchAllFor(chorusView.columns(), [rspecFixtures.databaseColumn()]);
            });

            it("renders successfully", function() {
                expect(this.view.$("li")).toExist();
            });
        });

        describe("when the 'datasetSelected' event is broadcast", function() {
            beforeEach(function() {
                this.table = rspecFixtures.dataset({ objectName: "brian_the_table", schema: {name: "john_the_schema"} });
                chorus.PageEvents.broadcast("datasetSelected", this.table);
            });

            it("should fetch the columns for the table", function() {
                expect(this.server.lastFetchFor(this.table.columns(), {page: 1, per_page: 1000})).toBeDefined();
            });

            context("when the fetch completes", function() {
                context("when there are no columns", function() {
                    beforeEach(function() {
                        this.server.completeFetchAllFor(this.table.columns(), []);
                    });

                    it("should show the 'no columns found' message", function() {
                        expect(this.view.$(".none_found")).toContainTranslation("schema.column.list.empty");
                    });
                });

                context("when there are columns", function() {
                    beforeEach(function() {
                        this.server.completeFetchAllFor(this.table.columns(), [
                            rspecFixtures.databaseColumn({name: "column_1"}),
                            rspecFixtures.databaseColumn({name: "column_2"})
                        ]);
                    });

                    it("should have data-cid on the list elements", function() {
                        expect(this.view.$('ul.list li')).toExist();
                        expect(this.view.$('ul.list li').data('cid')).toBeTruthy();
                    });

                    it("should have a collection defined", function() {
                        expect(this.view.collection).toBeTruthy();
                    });

                    it("should call super if overriding postRender", function() {
                        spyOn(chorus.views.DatabaseSidebarList.prototype, 'postRender');
                        this.view.render();
                        expect(chorus.views.DatabaseSidebarList.prototype.postRender).toHaveBeenCalled();
                    });

                    it("should have the fullname on the list elements", function() {
                        expect(this.view.$('ul.list li')).toExist();
                        expect(this.view.$('ul.list li').data('fullname')).toBeTruthy();
                    });

                    it("should make the list elements draggable", function() {
                        spyOn($.fn, "draggable");
                        this.view.render();
                        expect($.fn.draggable).toHaveBeenCalledOnSelector("ul.list li");
                    });

                    it("the draggable helper has the name of the table", function() {
                        var $li = this.view.$("ul.list li:eq(0)");
                        var helper = this.view.dragHelper({currentTarget: $li});
                        expect(helper).toHaveClass("drag_helper");
                        expect(helper).toContainText($li.data("name"));
                    });

                    it("should show a 'back to all datasets' link", function() {
                        expect(this.view.$("a.back").text()).toMatchTranslation("schema.column.list.back");
                    });

                    it("shows the table name next to the schema name", function() {
                        $("#jasmine_content").append(this.view.el);
                        expect(this.view.$(".context .schema")).toHaveText(this.table.schema.name);
                        expect(this.view.$(".context .schema")).toHaveAttr("title", this.table.schema.name);

                        expect(this.view.$(".context .table")).toHaveText("brian_the_table");
                        expect(this.view.$(".context .table")).toHaveAttr("title", "brian_the_table");
                    });

                    it("should show an 'li' for each column", function() {
                        expect(this.view.$("li").length).toBe(2);
                        expect(this.view.$("li").eq(0)).toContainText("column_1");
                        expect(this.view.$("li").eq(1)).toContainText("column_2");
                    });

                    context("when the 'back to all datasets' link is clicked", function() {
                        beforeEach(function() {
                            spyOnEvent(this.view, "back");
                            this.view.$("a.back").click();
                        });

                        it("should trigger a 'back' event", function() {
                            expect("back").toHaveBeenTriggeredOn(this.view);
                        });
                    });

                    describe("when switching to another dataset", function() {
                        beforeEach(function() {
                            this.newTable = rspecFixtures.dataset({
                                objectName: "jack_the_table",
                                schema: { name: "harry_the_schema" }
                            });

                            chorus.PageEvents.broadcast("datasetSelected", this.newTable);
                        });

                        it("fetches the new columns", function() {
                            expect(this.server.lastFetchFor(this.newTable.columns())).toBeDefined();
                        });

                        context("when the fetch completes", function() {
                            beforeEach(function() {
                                this.server.completeFetchAllFor(this.newTable.columns(), [
                                    rspecFixtures.databaseColumn({name: "column_a"}),
                                    rspecFixtures.databaseColumn({name: "column_b"}),
                                    rspecFixtures.databaseColumn({name: "column_c"})
                                ]);
                            });

                            it("re-renders the column list", function() {
                                expect(this.view.$("li").length).toBe(3);
                            });

                            describe("when switching back to the first dataset", function() {
                                beforeEach(function() {
                                    chorus.PageEvents.broadcast("datasetSelected", this.table);
                                });

                                it("fetches the new columns", function() {
                                    expect(this.server.lastFetchFor(this.table.columns())).toBeDefined();
                                });

                                context("when the fetch completes", function() {
                                    beforeEach(function() {
                                        this.server.completeFetchAllFor(this.table.columns(), [
                                            rspecFixtures.databaseColumn({name: "column_1"}),
                                            rspecFixtures.databaseColumn({name: "column_2"})
                                        ]);
                                    });

                                    it("re-renders the column list", function() {
                                        expect(this.view.$("li").length).toBe(2);
                                    });
                                });
                            });
                        });
                    });
                });
            });
        });
    });
});
