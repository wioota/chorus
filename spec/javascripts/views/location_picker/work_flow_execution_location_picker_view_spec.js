describe("chorus.views.WorkFlowExecutionLocationPicker", function() {
    describe("#render", function() {
        function itDisplaysLoadingPlaceholderFor(type) {
            it("displays the loading placeholder for " + type, function() {
                var className = _.str.underscored(type);
                expect(this.view.$("." + className + " .loading_text")).not.toHaveClass("hidden");
                expect(this.view.$("." + className + " select")).toBeHidden();
                expect(this.view.$('.' + className + ' label ')).not.toHaveClass("hidden");
                expect(this.view.$('.' + className + ' .unavailable')).toHaveClass("hidden");

                // Remove when adding "register a new data source" story
                if(type !== "dataSource") {
                    expect(this.view.$('.' + className + ' a')).not.toHaveClass("hidden");
                }
            });
        }

        function itDisplaysDefaultOptionFor(type) {
            it("displays the default option for '" + type + "'", function() {
                var className = _.str.underscored(type);
                expect(this.view.$("." + className + " select option:eq(0)").text()).toMatchTranslation("sandbox.select_one");
            });
        }

        function itTriggersTheChangeEvent(expectedArg) {
            it("triggers the 'change' event on itself", function() {
                if(expectedArg === undefined) {
                    expect("change").toHaveBeenTriggeredOn(this.view);
                } else {
                    expect("change").toHaveBeenTriggeredOn(this.view, [expectedArg]);
                }
            });
        }

        function itShouldResetSelect(type, changeArgument) {
            it("should reset " + type + " select", function() {
                expect(this.view.$('.' + type + ' select option:selected').val()).toBeFalsy();
                expect(this.view.$('.' + type + ' select option').length).toBe(1);
                expect('clearErrors').toHaveBeenTriggeredOn(this.view);
            });

            itTriggersTheChangeEvent(changeArgument);
        }

        function itHidesSection(type) {
            it("should hide the " + type + " section", function() {
                expect(this.view.$('.' + type)).toHaveClass("hidden");
            });
        }

        function itPopulatesSelect(type) {
            it("populates the select for for " + type + "s", function() {
                var escapedName = Handlebars.Utils.escapeExpression(this.view.getPickerSubview(type).collection.models[0].get('name'));
                var className = _.str.underscored(type);
                expect(this.view.$("." + className + " select option:eq(1)").text()).toBe(escapedName);
            });
        }

        function itShowsSelect(type) {
            it("should show the " + type + " select and hide the 'unavailable' message", function() {
                var className = _.str.underscored(type);
                expect(this.view.$('.' + className + ' label ')).not.toHaveClass("hidden");
                expect(this.view.$('.' + className + ' select option').length).toBeGreaterThan(1);
                expect(this.view.$('.' + className + ' select')).not.toHaveClass("hidden");
            });
        }

        function itShowsUnavailable(type) {
            it("should show the 'unavailable' text for the " + type + " section and hide the select", function() {
                var className = _.str.underscored(type);
                expect(this.view.$('.' + className + ' .unavailable')).not.toHaveClass("hidden");
                expect(this.view.$('.' + className + ' .loading_text')).toHaveClass("hidden");
                expect(this.view.$('.' + className + ' .select_container')).toHaveClass("hidden");
            });
        }

        function itShowsUnavailableTextWhenResponseIsEmptyFor(type) {
            context("when the response is empty for " + type, function() {
                beforeEach(function() {
                    var collection = this.view.getPickerSubview(type).collection;
                    expect(collection).not.toBeFalsy();
                    if(type === 'dataSource') {
                        this.server.completeFetchAllFor(collection, []);
                    } else {
                        this.server.completeFetchFor(collection, []);
                    }
                });

                itShowsUnavailable(type);
            });
        }

        function itShowsCreateFields(type) {
            it("shows the fields to create a new " + type, function() {
                expect(this.view.$(".create_container")).not.toHaveClass("hidden");
                expect(this.view.$('.' + type + ' .unavailable')).toHaveClass("hidden");
                expect(this.view.$('.' + type + ' .loading_text')).toHaveClass("hidden");
                expect(this.view.$('.' + type + ' .select_container')).toHaveClass("hidden");
            });
        }

        function itSortsTheSelectOptionsAlphabetically(type) {
            it("sorts the select options alphabetically for " + type, function() {

                if(type === "dataSource") {
                    this.server.completeFetchAllFor(this.view.dataSourceView.collection, [
                        rspecFixtures.gpdbDataSource({name: "Zoo"}),
                        rspecFixtures.gpdbDataSource({name: "Aardvark"}),
                        rspecFixtures.gpdbDataSource({name: "bear"})
                    ]);
                } else if(type === "schema") {
                    this.server.completeFetchFor(this.view.schemaView.collection, [
                        rspecFixtures.schema({name: "Zoo"}),
                        rspecFixtures.schema({name: "Aardvark"}),
                        rspecFixtures.schema({name: "bear"})
                    ]);
                } else { // type === 'database'
                    this.server.completeFetchFor(this.view.databaseView.collection, [
                        rspecFixtures.database({name: "Zoo"}),
                        rspecFixtures.database({name: "Aardvark"}),
                        rspecFixtures.database({name: "bear"})]);
                }

                var className = _.str.underscored(type);
                expect(this.view.$("." + className + " select option:eq(1)").text()).toBe("Aardvark");
                expect(this.view.$("." + className + " select option:eq(2)").text()).toBe("bear");
                expect(this.view.$("." + className + " select option:eq(3)").text()).toBe("Zoo");
            });
        }

        beforeEach(function() {
            stubDefer();
            spyOn(chorus, 'styleSelect');
        });

        context('when data source is provided', function() {
            beforeEach(function() {
                this.dataSource = rspecFixtures.gpdbDataSource();
                this.view = new chorus.views.WorkFlowExecutionLocationPicker({ dataSource: this.dataSource });
                $("#jasmine_content").append(this.view.el);
                this.view.render();
            });

            it('does not try to fetch the data sources', function() {
                expect(this.server.lastFetchAllFor(new chorus.collections.GpdbDataSourceSet())).toBeUndefined();
            });

            it('displays the data source name as a label instead of Select Data Source', function() {
                expect(this.view.$(".data_source .title")).toContainText(this.dataSource.name());
                expect(this.view.$('.data_source select')).not.toExist();
            });

            it("fetches the databases", function() {
                expect(this.server.lastFetchFor(this.dataSource.databases())).toBeDefined();
            });
        });

        context('when a data source and a database are provided', function() {
            beforeEach(function() {
                this.dataSource = rspecFixtures.gpdbDataSource();
                this.database = rspecFixtures.database({dataSource: { id: this.dataSource.get("id") } });
                this.database.unset('id');
                this.view = new chorus.views.WorkFlowExecutionLocationPicker({ dataSource: this.dataSource, database: this.database });

                $("#jasmine_content").append(this.view.el);
                this.view.render();
            });

            it('does not try to fetch the data sources or the databases', function() {
                expect(this.server.lastFetchAllFor(new chorus.collections.GpdbDataSourceSet())).toBeUndefined();
                expect(this.server.lastFetchAllFor(new chorus.collections.DatabaseSet({dataSourceId: this.dataSource.get("id")}))).toBeUndefined();
            });

            it('displays the data source and database names instead of selects for data sources and databases', function() {
                expect(this.view.$(".data_source .title")).toContainText(this.dataSource.name());
                expect(this.view.$(".database .title")).toContainText(this.database.name());

                expect(this.view.$('.data_source select')).not.toExist();
                expect(this.view.$('.database select')).not.toExist();
            });
        });

        context("when nothing is provided", function() {
            context("when allowCreate is true", function() {
                beforeEach(function() {
                    this.view = new chorus.views.WorkFlowExecutionLocationPicker({ allowCreate: true });
                    spyOnEvent(this.view, 'change');
                    spyOnEvent(this.view, 'clearErrors');
                    this.view.render();
                    this.dialogContainer = $("<div class='dialog sandbox_new'></div>").append(this.view.el);
                    $('#jasmine_content').append(this.dialogContainer);
                });

                it("includes accessible=true by default", function() {
                    expect(this.server.lastFetch().url).toContainQueryParams({accessible: true});
                });

                it('renders a select for the data source', function() {
                    expect(this.view.$('.data_source select')).toExist();
                    expect(this.view.$('.data_source .title')).not.toExist();
                });

                it("fetches the list of data sources", function() {
                    expect(this.server.requests[0].url).toMatch("/data_sources/");
                });

                itDisplaysLoadingPlaceholderFor('dataSource');

                itShowsUnavailableTextWhenResponseIsEmptyFor('dataSource');

                itSortsTheSelectOptionsAlphabetically('dataSource');

                context('when the data source list fetch completes', function() {
                    beforeEach(function() {
                        this.server.completeFetchAllFor(this.view.dataSourceView.collection, [
                            rspecFixtures.gpdbDataSource({ name: "<script>alert(hi)<script>", shared: true, id: 1 }),
                            rspecFixtures.gpdbDataSource({ shared: true, id: 2 }),
                            rspecFixtures.gpdbDataSource({ shared: false, id: 3 })
                        ]);
                    });

                    itShowsSelect('dataSource');
                    itPopulatesSelect('dataSource');
                    itHidesSection('database');

                    itDisplaysDefaultOptionFor('dataSource');

                    it("hides the loading placeholder", function() {
                        expect(this.view.$(".data_source .loading_text")).toHaveClass("hidden");
                    });

                    describe("when the view re-renders due to its parent re-rendering", function() {
                        beforeEach(function() {
                            this.view.render();
                        });

                        it("still hides the loading placeholder", function() {
                            expect(this.view.$(".data_source .loading_text")).toHaveClass("hidden");
                        });

                        it('keeps the same options in the data source select', function() {
                            expect(this.view.$("select[name=data_source] option").length).toBe(4);
                        });
                    });

                    context('choosing a data source', function() {
                        beforeEach(function() {
                            this.view.$(".data_source select").prop("selectedIndex", 1).change();
                            this.selectedDataSource = this.view.dataSourceView.collection.get(this.view.$('.data_source select option:selected').val());
                        });

                        itDisplaysLoadingPlaceholderFor('database');
                        itTriggersTheChangeEvent(false);

                        context("when the response is empty for databases", function() {
                            beforeEach(function() {
                                this.server.completeFetchFor(this.view.databaseView.collection, []);
                            });

                            itShowsUnavailable("database");

                            describe('choosing another data source', function() {
                                beforeEach(function() {
                                    this.view.$(".data_source select").prop("selectedIndex", 2).change();
                                });

                                itDisplaysLoadingPlaceholderFor('database');
                            });
                        });

                        it("fetches the list of databases", function() {
                            expect(this.server.requests[1].url).toMatch("/data_sources/" + this.selectedDataSource.get('id') + "/databases");
                        });

                        itSortsTheSelectOptionsAlphabetically('database');

                        context("when the database list fetch completes", function() {
                            beforeEach(function() {
                                this.server.completeFetchFor(this.view.databaseView.collection, [rspecFixtures.database(), rspecFixtures.database()]);
                            });

                            itShowsSelect('database');
                            itPopulatesSelect('database');
                            itDisplaysDefaultOptionFor('database');

                            it("hides the loading placeholder", function() {
                                expect(this.view.$(".database .loading_text")).toHaveClass("hidden");
                            });

                            it("shows the 'new database' link", function() {
                                expect(this.view.$(".database a.new")).not.toHaveClass("hidden");
                            });

                            context("choosing a database", function() {
                                beforeEach(function() {
                                    this.view._chorusEventSpies["change"].reset();
                                    var select = this.view.$(".database select");
                                    select.prop("selectedIndex", 1);
                                    select.change();
                                    this.selectedDatabase = this.view.databaseView.collection.get(this.view.$('.database select option:selected').val());
                                });

                                itTriggersTheChangeEvent(false);
                            });
                        });

                        context("when the database list fetch fails", function() {
                            beforeEach(function() {
                                spyOnEvent(this.view, 'error');
                                this.server.lastFetchAllFor(this.view.databaseView.collection).failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
                            });

                            it("hides the loading section", function() {
                                expect(this.view.$(".database .loading_text")).toHaveClass("hidden");
                            });

                            it("triggers error with the message", function() {
                                expect("error").toHaveBeenTriggeredOn(this.view, [this.view.databaseView.collection]);
                            });
                        });
                    });
                });

                context('when the data source list fetch completes without any data sources', function() {
                    beforeEach(function() {
                        this.server.completeFetchAllFor(this.view.dataSourceView.collection, []);
                    });

                    itShowsUnavailable('dataSource');
                    itHidesSection('database');
                });

                context('when the data source list fetch fails', function() {
                    beforeEach(function() {
                        spyOnEvent(this.view, 'error');
                        this.server.lastFetchAllFor(this.view.dataSourceView.collection).failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
                    });

                    it("triggers error with the message", function() {
                        expect("error").toHaveBeenTriggeredOn(this.view, [this.view.dataSourceView.collection]);
                    });
                });

                context("when allowCreate is false", function() {
                    beforeEach(function() {
                        this.view = new chorus.views.WorkFlowExecutionLocationPicker({ allowCreate: false });
                        this.view.render();
                        this.dialogContainer = $("<div class='dialog sandbox_new'></div>").append(this.view.el);
                        $('#jasmine_content').append(this.dialogContainer);
                    });

                    it("does not render creation markup", function() {
                        expect(this.view.$(".database a.new")).not.toExist();
                        expect(this.view.$(".database .create_container")).not.toExist();
                        expect(this.view.$(".schema a.new")).not.toExist();
                        expect(this.view.$(".schema .create_container")).not.toExist();
                    });
                });
            });
        });

        describe("#fieldValues", function() {
            context('with a data source provided', function() {
                beforeEach(function() {
                    this.dataSource = rspecFixtures.gpdbDataSource();
                    this.view = new chorus.views.WorkFlowExecutionLocationPicker({ dataSource: this.dataSource });
                    this.view.render();
                    this.server.completeFetchFor(this.view.databaseView.collection, [ rspecFixtures.database({ id: '5' }) ]);
                    this.view.$(".database select").val("5").change();
                    this.server.completeFetchAllFor(this.view.schemaView.collection, [ rspecFixtures.schema({ id: '6' }) ]);
                    this.view.$(".schema select").val("6").change();
                });

                it('uses the provided data source', function() {
                    expect(this.view.fieldValues()).toEqual({
                        dataSource: this.dataSource.get('id'),
                        database: '5',
                        schema: '6'
                    });
                });
            });

            context('with no data source provided', function() {
                beforeEach(function() {
                    this.view = new chorus.views.WorkFlowExecutionLocationPicker({ allowCreate: true });
                    $('#jasmine_content').append(this.view.el);
                    this.view.render();
                    this.server.completeFetchAllFor(this.view.dataSourceView.collection, [ rspecFixtures.gpdbDataSource({ id: '4' }) ]);
                    this.view.$(".data_source select").val("4").change();
                });

                context('when a data source, database, and schema are selected from the dropdowns', function() {
                    beforeEach(function() {
                        this.server.completeFetchFor(this.view.databaseView.collection, [ rspecFixtures.database({ id: '5' }) ]);
                        this.view.$(".database select").val("5").change();
                        this.server.completeFetchAllFor(this.view.schemaView.collection, [ rspecFixtures.schema({ id: '6' }) ]);
                        this.view.$(".schema select").val("6").change();
                    });

                    it('returns data source, database, and schema ids', function() {
                        expect(this.view.fieldValues()).toEqual({
                            dataSource: '4',
                            database: '5',
                            schema: '6'
                        });
                    });
                });

                context("when the user enters new database and schema names", function() {
                    beforeEach(function() {
                        this.view.$(".database a.new").click();
                        this.view.$(".database input.name").val("New_Database");
                        this.view.$(".schema input.name").val("New_Schema").keyup();
                    });

                    it('returns the data source id and the database and schema names', function() {
                        expect(this.view.fieldValues()).toEqual({
                            dataSource: '4',
                            databaseName: 'New_Database',
                            schemaName: 'New_Schema'
                        });
                    });
                });
            });
        });

        describe("#ready", function() {
            beforeEach(function() {
                this.view = new chorus.views.WorkFlowExecutionLocationPicker({ allowCreate: true });
            });

            context('when a data source, database, and schema are selected', function() {
                beforeEach(function() {
                    spyOn(this.view, "fieldValues").andReturn({
                        dataSource: 5,
                        database: 6,
                        schema: 7
                    });
                });

                it("return true", function() {
                    expect(this.view.ready()).toBeTruthy();
                });
            });

            context("when not completely specified", function() {
                context('with only a data source', function() {
                    beforeEach(function() {
                        spyOn(this.view, "fieldValues").andReturn({
                            dataSource: 5
                        });
                    });

                    it("return false", function() {
                        expect(this.view.ready()).toBeFalsy();
                    });
                });

                context('with a data source and a blank databaseName', function() {
                    beforeEach(function() {
                        spyOn(this.view, "fieldValues").andReturn({
                            dataSource: 5,
                            databaseName: ""
                        });
                    });

                    it("return false", function() {
                        expect(this.view.ready()).toBeFalsy();
                    });
                });

                context('with a data source, a database, and a blank schemaName', function() {
                    beforeEach(function() {
                        spyOn(this.view, "fieldValues").andReturn({
                            dataSource: 5,
                            database: 6,
                            schemaName: ""
                        });
                    });

                    it("return false", function() {
                        expect(this.view.ready()).toBeFalsy();
                    });
                });
            });

            context("with showSchemaSection false", function() {
                beforeEach(function() {
                    this.view = new chorus.views.WorkFlowExecutionLocationPicker({ allowCreate: true, showSchemaSection: false });
                });

                context('with only a data source', function() {
                    beforeEach(function() {
                        spyOn(this.view, "fieldValues").andReturn({
                            dataSource: 5
                        });
                    });

                    it("return false", function() {
                        expect(this.view.ready()).toBeFalsy();
                    });
                });

                context('with a data source and a blank databaseName', function() {
                    beforeEach(function() {
                        spyOn(this.view, "fieldValues").andReturn({
                            dataSource: 5,
                            databaseName: ""
                        });
                    });

                    it("return false", function() {
                        expect(this.view.ready()).toBeFalsy();
                    });
                });

                context('with a data source, a database, and a blank schemaName', function() {
                    beforeEach(function() {
                        spyOn(this.view, "fieldValues").andReturn({
                            dataSource: 5,
                            database: 6,
                            schemaName: ""
                        });
                    });

                    it("return false", function() {
                        expect(this.view.ready()).toBeTruthy();
                    });
                });
            });
        });

    });
});
