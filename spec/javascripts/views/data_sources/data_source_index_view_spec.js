describe("chorus.views.DataSourceIndex", function() {
    beforeEach(function() {
        this.dataSources = new chorus.collections.DataSourceSet();
        this.hdfsDataSources = new chorus.collections.HdfsDataSourceSet();
        this.gnipDataSources = new chorus.collections.GnipDataSourceSet();
        this.dataSources.fetch();
        this.hdfsDataSources.fetch();
        this.gnipDataSources.fetch();

        this.view = new chorus.views.DataSourceIndex({
            dataSources: this.dataSources,
            hdfsDataSources: this.hdfsDataSources,
            gnipDataSources: this.gnipDataSources
        });
        this.view.render();
    });

    context('without data sources', function() {
        describe("#render", function() {
            it('renders empty text for each data source type', function() {
                expect(this.view.$(".data_source .no_data_sources").text().trim()).toMatchTranslation("instances.none");
                expect(this.view.$(".hdfs_data_source .no_data_sources").text().trim()).toMatchTranslation("instances.none");
                expect(this.view.$(".gnip_data_source .no_data_sources").text().trim()).toMatchTranslation("instances.none");
            });
        });
    });

    context('when the data sources are fetched', function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.dataSources, [
                rspecFixtures.gpdbDataSource({name : "GP9", id: "1"}),
                rspecFixtures.gpdbDataSource({name : "gP1", id: "2"}),
                rspecFixtures.oracleDataSource({name : "oracle", id: "3"})
            ]);
            this.server.completeFetchFor(this.hdfsDataSources, [
                rspecFixtures.hdfsDataSource({name : "Hadoop9", id: "1"}),
                rspecFixtures.hdfsDataSource({name : "hadoop1", id: "2"}),
                rspecFixtures.hdfsDataSource({name : "Hadoop10", id: "3"})
            ]);
            this.server.completeFetchFor(this.gnipDataSources, [
                rspecFixtures.gnipDataSource({name : "Gnip1", id:"1"}),
                rspecFixtures.gnipDataSource({name : "Gnip2", id: "2"}),
                rspecFixtures.gnipDataSource({name : "Gnip3", id: "3"})
            ]);
        });

        it("should display the selectable list styling", function() {
            expect(this.view.$("ul.list")).toHaveClass("selectable");
        });

        it('renders the three data source provider sections', function() {
            expect(this.view.$("div.data_source_provider").length).toBe(3);
        });

        it('renders the details section in each data source provider section', function() {
            expect(this.view.$("div.data_source_provider .details").length).toBe(3);
        });

        it('renders the data sources in the correct data source div', function() {
            var dataSources = this.view.$(".data_source li");
            expect(dataSources.length).toBe(3);
            expect(dataSources).toContainText("gP1");
            expect(dataSources).toContainText("GP9");
            expect(dataSources).toContainText("oracle");
        });

        it('renders the hadoop data sources in the correct data source div', function() {
            var hadoopItems = this.view.$(".hdfs_data_source li");
            expect(hadoopItems.length).toBe(3);
            expect(hadoopItems).toContainText("hadoop1");
            expect(hadoopItems).toContainText("Hadoop9");
            expect(hadoopItems).toContainText("Hadoop10");
        });

        it('renders the gnip data sources in the correct data source div', function() {
            var gnipItems = this.view.$(".gnip_data_source li");
            expect(gnipItems.length).toBe(3);
            expect(gnipItems).toContainText("Gnip1");
            expect(gnipItems).toContainText("Gnip2");
            expect(gnipItems).toContainText("Gnip3");
        });

        it('pre-selects the first data source', function() {
            expect(this.view.$("li:first-child")).toHaveClass("selected");
            expect(this.view.$("li.selected").length).toBe(1);
            expect(this.view.$("li.selected")).toContainText('gP1');
        });

        describe('when a data source is offline', function() {
            beforeEach(function() {
                this.dataSources.at(0).set({ name: "Greenplum", online: false });
                this.view.render();
            });

            it("should display the unknown state icon", function() {
                expect(this.view.$(".data_source li:eq(0) img.state")).toHaveAttr("src", "/images/data_sources/yellow.png");
            });

            it("should display the name as a link", function() {
                expect(this.view.$(".data_source li:eq(0) a.name")).toExist();
                expect(this.view.$(".data_source li:eq(0) a.name")).toContainText("Greenplum");
            });
        });

        describe("data_source:added event", function() {
            beforeEach(function() {
                this.newDataSource = rspecFixtures.oracleDataSource({id: 31415, name: "new data source"});
                spyOn(this.view.dataSources, "fetchAll").andCallThrough();
                spyOn(this.view.hdfsDataSources, "fetchAll").andCallThrough();
                spyOn(this.view.gnipDataSources, "fetchAll").andCallThrough();
                chorus.PageEvents.broadcast("data_source:added", this.newDataSource);
            });

            it('re-fetches the data sources, hadoop and gnip data sources', function() {
                expect(this.view.dataSources.fetchAll).toHaveBeenCalled();
                expect(this.view.hdfsDataSources.fetchAll).toHaveBeenCalled();
                expect(this.view.gnipDataSources.fetchAll).toHaveBeenCalled();
            });

            it("selects the li with a matching id when fetch completes", function() {
                this.server.completeFetchFor(this.dataSources, [
                    rspecFixtures.gpdbDataSource({name : "GP9", id: "1"}),
                    rspecFixtures.gpdbDataSource({name : "gP1", id: "2"}),
                    this.newDataSource,
                    rspecFixtures.oracleDataSource({name : "oracle", id: "3"})
                ]);
                this.server.completeFetchFor(this.hdfsDataSources, [
                    rspecFixtures.hdfsDataSource({name : "Hadoop9", id: "1"}),
                    rspecFixtures.hdfsDataSource({name : "hadoop1", id: "2"}),
                    rspecFixtures.hdfsDataSource({name : "Hadoop10", id: "3"})
                ]);
                this.server.completeFetchFor(this.gnipDataSources, [
                    rspecFixtures.gnipDataSource({name : "Gnip1", id:"1"}),
                    rspecFixtures.gnipDataSource({name : "Gnip2", id: "2"}),
                    rspecFixtures.gnipDataSource({name : "Gnip3", id: "3"})
                ]);
                expect(this.view.$("li.selected .name")).toHaveText("new data source");
            });
        });


        describe("checking a data source checkbox", function() {
            it("broadcasts the selected event with the right models", function() {
                spyOn(chorus.PageEvents, 'broadcast');
                this.view.$("li input:checkbox").eq(0).click().change();
                expect(chorus.PageEvents.broadcast).toHaveBeenCalled();
                var lastTwoCalls = chorus.PageEvents.broadcast.calls.slice(-2);
                var eventName = lastTwoCalls[1].args[0];
                expect(eventName).toEqual("data_source:checked");
                var selectedModelsCollection = lastTwoCalls[0].args[1];
                expect(selectedModelsCollection.length).toEqual(1);
            });
        });

        describe("rendering the checkboxes", function() {
            it("ensures that selected models are checked", function() {
                expect(this.view.$("input:checked").length).toBe(0);
                this.view.selectedModels.reset([
                    this.dataSources.at(0),
                    this.hdfsDataSources.at(0)
                ]);
                chorus.PageEvents.broadcast('checked', this.view.selectedModels);
                chorus.PageEvents.broadcast('data_source:checked', this.view.selectedModels);
                expect(this.view.$("input:checked").length).toBe(2);

                var selectedDataSourceCheckbox = this.view.$("input[type=checkbox]").eq(0);
                expect(selectedDataSourceCheckbox).toBeChecked();

                var selectedHdfsDataSourceCheckbox = this.view.$("input[type=checkbox]").eq(3);
                expect(selectedHdfsDataSourceCheckbox).toBeChecked();

                var unselectedModelCheckbox = this.view.$("input[type=checkbox]").eq(1);
                expect(unselectedModelCheckbox).not.toBeChecked();
            });

            it("allows models of different entity types to share an id", function() {
                this.view.selectedModels.reset([
                    rspecFixtures.gpdbDataSource({id: 1}),
                    rspecFixtures.hdfsDataSource({id: 1})
                ]);
                expect(this.view.selectedModels.length).toBe(2);
            });
        });
    });
});
