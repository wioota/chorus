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
                    if(type === 'dataSource') {
                        var gpdbDataSources = this.view.getPickerSubview(type).gpdbDataSources;
                        var hdfsDataSources = this.view.getPickerSubview(type).hdfsDataSources;
                        expect(gpdbDataSources).not.toBeFalsy();
                        expect(hdfsDataSources).not.toBeFalsy();
                        this.server.completeFetchAllFor(gpdbDataSources, []);
                        this.server.completeFetchAllFor(hdfsDataSources, []);
                    } else {
                        var collection = this.view.getPickerSubview(type).collection;
                        expect(collection).not.toBeFalsy();
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
                    this.server.completeFetchAllFor(this.view.dataSourceView.gpdbDataSources, [
                        backboneFixtures.gpdbDataSource({name: "bear"})
                    ]);
                    this.server.completeFetchAllFor(this.view.dataSourceView.hdfsDataSources, [
                        backboneFixtures.hdfsDataSource({name: "Zoo"}),
                        backboneFixtures.hdfsDataSource({name: "Aardvark"})
                    ]);
                } else if(type === "schema") {
                    this.server.completeFetchFor(this.view.schemaView.collection, [
                        backboneFixtures.schema({name: "Zoo"}),
                        backboneFixtures.schema({name: "Aardvark"}),
                        backboneFixtures.schema({name: "bear"})
                    ]);
                } else { // type === 'database'
                    this.server.completeFetchFor(this.view.databaseView.collection, [
                        backboneFixtures.database({name: "Zoo"}),
                        backboneFixtures.database({name: "Aardvark"}),
                        backboneFixtures.database({name: "bear"})]);
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

        context("when nothing is provided", function() {
            beforeEach(function() {
                this.view = new chorus.views.WorkFlowExecutionLocationPicker();
                spyOnEvent(this.view, 'change');
                spyOnEvent(this.view, 'clearErrors');
                this.view.render();
                this.dialogContainer = $("<div class='dialog sandbox_new'></div>").append(this.view.el);
                $('#jasmine_content').append(this.dialogContainer);
            });

            it("includes accessible=true by default", function() {
                expect(this.server.requests[0].url).toContainQueryParams({accessible: true});
            });

            it("fetches the list of data sources", function() {
                expect(this.server.requests[0].url).toMatch("/data_sources/");
                expect(this.server.requests[1].url).toMatch("/hdfs_data_sources");
            });

            itDisplaysLoadingPlaceholderFor('dataSource');

            itShowsUnavailableTextWhenResponseIsEmptyFor('dataSource');

            itSortsTheSelectOptionsAlphabetically('dataSource');

            context('when the data source list fetches complete', function() {
                beforeEach(function() {
                    this.firstGdpbDataSource = backboneFixtures.gpdbDataSource({ name: "alphabeticalA", shared: true, id: 1 });
                    this.server.completeFetchAllFor(this.view.dataSourceView.gpdbDataSources, [
                        this.firstGdpbDataSource,
                        backboneFixtures.gpdbDataSource({ name: "alphabeticalC", shared: true, id: 2 }),
                        backboneFixtures.gpdbDataSource({ name: "alphabeticalD", shared: false, id: 3 })
                    ]);

                    this.firstHdfsDataSource = backboneFixtures.hdfsDataSource({name: "alphabeticalB", id: 1});
                    this.server.completeFetchAllFor(this.view.dataSourceView.hdfsDataSources, [
                        this.firstHdfsDataSource,
                        backboneFixtures.hdfsDataSource({ name: "alphabeticalE", id: 2 }),
                        backboneFixtures.hdfsDataSource({ name: "alphabeticalF", id: 3 })
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
                        expect(this.view.$("select[name=data_source] option").length).toBe(7);
                    });
                });

                context('choosing a gpdb data source', function() {
                    beforeEach(function() {
                        this.server.reset();
                        this.view.$(".data_source select").prop("selectedIndex", 1).change();
                    });

                    itDisplaysLoadingPlaceholderFor('database');
                    itTriggersTheChangeEvent(false);

                    context("when the response is empty for databases", function() {
                        beforeEach(function() {
                            this.server.completeFetchFor(this.view.databaseView.collection, []);
                        });

                        itShowsUnavailable("database");

                        describe('choosing another gpdb data source', function() {
                            beforeEach(function() {
                                this.view.$(".data_source select").prop("selectedIndex", 3).change();
                            });

                            itDisplaysLoadingPlaceholderFor('database');
                        });
                    });

                    it("fetches the list of databases", function() {
                        expect(this.server.requests[0].url).toMatch("/data_sources/" + this.firstGdpbDataSource.get('id') + "/databases");
                    });

                    itSortsTheSelectOptionsAlphabetically('database');

                    context("when the database list fetch completes", function() {
                        beforeEach(function() {
                            this.server.completeFetchFor(this.view.databaseView.collection, [backboneFixtures.database(), backboneFixtures.database()]);
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

                            itTriggersTheChangeEvent(true);
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

                        it("triggers an error with the message", function() {
                            expect("error").toHaveBeenTriggeredOn(this.view, [this.view.databaseView.collection]);
                        });
                    });
                });

                context('choosing an hdfs data source', function() {
                    beforeEach(function() {
                        this.server.reset();
                        this.view.$(".data_source select").prop("selectedIndex", 2).change();
                    });

                    itTriggersTheChangeEvent();

                    it("does not fetch", function() {
                        expect(this.server.requests.length).toBe(0);
                    });
                });
            });

            context('when the data source list fetch completes without any data sources', function() {
                beforeEach(function() {
                    this.server.completeFetchAllFor(this.view.dataSourceView.gpdbDataSources, []);
                    this.server.completeFetchAllFor(this.view.dataSourceView.hdfsDataSources, []);
                });

                itShowsUnavailable('dataSource');
                itHidesSection('database');
            });

            context('when one of the data source list fetches fails', function() {
                beforeEach(function() {
                    spyOnEvent(this.view, 'error');
                    this.server.lastFetchAllFor(this.view.dataSourceView.gpdbDataSources).failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
                    this.server.completeFetchAllFor(this.view.dataSourceView.hdfsDataSources, []);
                });

                it("triggers error with the message", function() {
                    expect("error").toHaveBeenTriggeredOn(this.view, [this.view.dataSourceView.gpdbDataSources]);
                });
            });

            it("does not render creation markup", function() {
                expect(this.view.$(".database a.new")).not.toExist();
                expect(this.view.$(".database .create_container")).not.toExist();
                expect(this.view.$(".schema a.new")).not.toExist();
                expect(this.view.$(".schema .create_container")).not.toExist();
            });
        });

        describe("#ready", function() {
            beforeEach(function() {
                this.view = new chorus.views.WorkFlowExecutionLocationPicker();
            });

            context('when a data source, database, and schema are selected', function() {
                beforeEach(function() {
                    spyOn(this.view.databaseView, "fieldValues").andReturn({
                        database: 6
                    });
                    spyOn(this.view.dataSourceView, "fieldValues").andReturn({
                        dataSource: 5
                    });
                });

                it("return true", function() {
                    expect(this.view.ready()).toBeTruthy();
                });
            });

            context("when not completely specified", function() {
                context('with only a data source', function() {
                    beforeEach(function() {
                        spyOn(this.view.dataSourceView, "fieldValues").andReturn({
                            dataSource: 5
                        });
                    });

                    it("return false", function() {
                        expect(this.view.ready()).toBeFalsy();
                    });
                });

                context('with a data source and a blank databaseName', function() {
                    beforeEach(function() {
                        spyOn(this.view.dataSourceView, "fieldValues").andReturn({
                            dataSource: 5
                        });

                        spyOn(this.view.databaseView, "fieldValues").andReturn({
                            databaseName: ""
                        });
                    });

                    it("return false", function() {
                        expect(this.view.ready()).toBeFalsy();
                    });
                });

                context('with a data source and a database', function() {
                    beforeEach(function() {
                        spyOn(this.view.dataSourceView, "fieldValues").andReturn({
                            dataSource: 5
                        });
                        spyOn(this.view.databaseView, "fieldValues").andReturn({
                            database: 6
                        });
                    });

                    it("return true", function() {
                        expect(this.view.ready()).toBeTruthy();
                    });
                });
            });
        });
    });
});
