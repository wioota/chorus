describe("chorus.views.InstanceList", function() {
    beforeEach(function() {
        this.dataSources = new chorus.collections.DataSourceSet();
        this.hadoopInstances = new chorus.collections.HadoopInstanceSet();
        this.gnipInstances = new chorus.collections.GnipInstanceSet();
        this.dataSources.fetch();
        this.hadoopInstances.fetch();
        this.gnipInstances.fetch();

        this.view = new chorus.views.InstanceList({
            dataSources: this.dataSources,
            hadoopInstances: this.hadoopInstances,
            gnipInstances: this.gnipInstances
        });
    });

    context('without data sources', function() {
        describe("#render", function() {
            beforeEach(function() {
                this.view.render();
            });

            it('renders empty text for each data source type', function() {
                expect(this.view.$(".data_source .no_instances").text().trim()).toMatchTranslation("instances.none");
                expect(this.view.$(".hadoop_instance .no_instances").text().trim()).toMatchTranslation("instances.none");
                expect(this.view.$(".gnip_instance .no_instances").text().trim()).toMatchTranslation("instances.none");
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
            this.server.completeFetchFor(this.hadoopInstances, [
                rspecFixtures.hadoopInstance({name : "Hadoop9", id: "1"}),
                rspecFixtures.hadoopInstance({name : "hadoop1", id: "2"}),
                rspecFixtures.hadoopInstance({name : "Hadoop10", id: "3"})
            ]);
            this.server.completeFetchFor(this.gnipInstances, [
                rspecFixtures.gnipInstance({name : "Gnip1", id:"1"}),
                rspecFixtures.gnipInstance({name : "Gnip2", id: "2"}),
                rspecFixtures.gnipInstance({name : "Gnip3", id: "3"})
            ]);
        });

        it("should display the selectable list styling", function() {
            expect(this.view.$("ul.list")).toHaveClass("selectable");
        });

        it('renders the three data source provider sections', function() {
            expect(this.view.$("div.instance_provider").length).toBe(3);
        });

        it('renders the details section in each data source provider section', function() {
            expect(this.view.$("div.instance_provider .details").length).toBe(3);
        });

        it('renders the data sources in the correct data source div', function() {
            var dataSources = this.view.$(".data_source li.instance");
            expect(dataSources.length).toBe(3);
            expect(dataSources).toContainText("gP1");
            expect(dataSources).toContainText("GP9");
            expect(dataSources).toContainText("oracle");
        });

        it('renders the hadoop data sources in the correct data source div', function() {
            var hadoopItems = this.view.$(".hadoop_instance li.instance");
            expect(hadoopItems.length).toBe(3);
            expect(hadoopItems).toContainText("hadoop1");
            expect(hadoopItems).toContainText("Hadoop9");
            expect(hadoopItems).toContainText("Hadoop10");
        });

        it('renders the gnip data sources in the correct data source div', function() {
            var gnipItems = this.view.$(".gnip_instance li.instance");
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

        describe('when a data source is destroyed', function() {
            beforeEach(function() {
                this.oldLength = this.dataSources.length;
                var liToSelect = this.view.$("li").eq(2);
                liToSelect.click();
                this.selectedId = liToSelect.data("instanceId");
            });

            context("when it is currently selected", function() {
                beforeEach(function() {
                    this.dataSources.get(this.selectedId).destroy();
                    this.server.lastDestroy().succeed();
                });

                it('selects the next available data source', function() {
                    expect(this.view.$("li:first-child")).toHaveClass("selected");
                    expect(this.view.$("li.selected").length).toBe(1);
                });

                it("renders only the existing items", function() {
                    expect(this.dataSources.models.length).toBe(this.oldLength - 1);
                    expect(this.view.$(".data_source li.instance").length).toBe(this.oldLength - 1);
                });
            });

            context('when a non-selected data source is destroyed', function() {
                beforeEach(function() {
                    var nonSelectedLi = this.view.$("li").not(".selected").eq(0);
                    var id = nonSelectedLi.data("instanceId");
                    this.dataSources.get(id).destroy();
                    this.server.lastDestroy().succeed();
                });

                it('leaves the same data source selected', function() {
                    expect(this.view.$("li.selected").data("instanceId")).toBe(this.selectedId);
                });
            });
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

        describe("instance:added event", function() {
            beforeEach(function() {
                this.newInstance = rspecFixtures.oracleDataSource({id: 31415});
                spyOn(this.view.dataSources, "fetchAll");
                spyOn(this.view.hadoopInstances, "fetchAll");
                spyOn(this.view.gnipInstances, "fetchAll");
                chorus.PageEvents.broadcast("instance:added", this.newInstance);
            });

            it('re-fetches the data sources, hadoop and gnip data sources', function() {
                expect(this.view.dataSources.fetchAll).toHaveBeenCalled();
                expect(this.view.hadoopInstances.fetchAll).toHaveBeenCalled();
                expect(this.view.gnipInstances.fetchAll).toHaveBeenCalled();
            });

            it("selects the li with a matching id when fetch completes", function() {
                this.dataSources.add(this.newInstance);
                this.view.render(); // re-renders when fetch completes

                expect(this.view.$("li[data-instance-id=31415]")).toHaveClass("selected");
                expect(this.view.$("li.selected").length).toBe(1);
            });
        });

        describe('clicking on a gpdbdata source', function() {
            beforeEach(function() {
                this.eventSpy = jasmine.createSpy("instance:selected");
                chorus.PageEvents.subscribe("instance:selected", this.eventSpy);
                this.li2 = this.view.$('li:contains("GP9")');
                this.li3 = this.view.$('li:contains("oracle")');
                this.li2.click();
            });

            it('triggers the instance:selected event', function() {
                expect(this.eventSpy).toHaveBeenCalled();
                var instancePassed = this.eventSpy.mostRecentCall.args[0];
                expect(instancePassed.get("name")).toBe("GP9");
            });

            it("adds the selected class to that item", function() {
                expect(this.li2).toHaveClass("selected");
            });

            describe("when the view re-renders", function() {
                beforeEach(function() {
                    this.view.render();
                });

                it("selects the li that was previously clicked", function() {
                    this.li2 = this.view.$('li:contains("GP9")');
                    expect(this.li2).toHaveClass("selected");
                });
            });

            context('clicking on the same data source again', function() {
                beforeEach(function() {
                    this.li2.click();
                });

                it("does not raise the event again", function() {
                    expect(this.eventSpy.calls.length).toBe(1);
                });
            });

            context('and then clicking on another data source', function() {
                beforeEach(function() {
                    this.li3.click();
                });

                it("removes the selected class from the first li", function() {
                    expect(this.li2).not.toHaveClass("selected");
                });
            });
        });

        describe('clicking on a hadoopdata source', function() {
            beforeEach(function() {
                this.eventSpy = jasmine.createSpy();
                chorus.PageEvents.subscribe("instance:selected", this.eventSpy);
                this.liToClick = this.view.$('li:contains("Hadoop10")');
                this.liToClick.click();
            });

            it("triggers the instance:selected event", function() {
                expect(this.eventSpy).toHaveBeenCalled();
                var instancePassed = this.eventSpy.mostRecentCall.args[0];
                expect(instancePassed.get("name")).toBe("Hadoop10");
            });

            it("adds the selected class to that item", function() {
                expect(this.liToClick).toHaveClass("selected");
            });
        });

        describe('clicking on a gnipdata source', function() {
            beforeEach(function() {
                this.eventSpy = jasmine.createSpy();
                chorus.PageEvents.subscribe("instance:selected", this.eventSpy);
                this.liToClick = this.view.$('li:contains("Gnip1")');
                this.liToClick.click();
            });

            it("triggers the instance:selected event", function() {
                expect(this.eventSpy).toHaveBeenCalled();
                var instancePassed = this.eventSpy.mostRecentCall.args[0];
                expect(instancePassed.get("name")).toBe("Gnip1");
            });

            it("adds the selected class to that item", function() {
                expect(this.liToClick).toHaveClass("selected");
            });
        });

        describe("checking a data source checkbox", function() {
            it("broadcasts the selected event with the right models", function() {
                spyOn(chorus.PageEvents, 'broadcast');
                this.view.$("li input:checkbox").eq(0).click().change();
                expect(chorus.PageEvents.broadcast).toHaveBeenCalled();
                var lastTwoCalls = chorus.PageEvents.broadcast.calls.slice(-2);
                var eventName = lastTwoCalls[1].args[0];
                expect(eventName).toEqual("instance:checked");
                var selectedModelsCollection = lastTwoCalls[0].args[1];
                expect(selectedModelsCollection.length).toEqual(1);
            });
        });

        describe("the collection that is used for multiple selections", function() {
            it("contains all of the data sources", function() {
                expect(this.view.collection.length).toEqual(9);
            });
        });

        describe("rendering the checkboxes", function() {
            it("ensures that selected models are checked", function() {
                this.view.selectedModels.reset([
                    this.dataSources.at(0),
                    this.hadoopInstances.at(0)
                ]);
                this.view.render();

                var selectedDataSourceCheckbox = this.view.$("input[type=checkbox]").eq(0);
                expect(selectedDataSourceCheckbox).toBeChecked();

                var selectedHadoopInstanceCheckbox = this.view.$("input[type=checkbox]").eq(3);
                expect(selectedHadoopInstanceCheckbox).toBeChecked();

                var unselectedModelCheckbox = this.view.$("input[type=checkbox]").eq(1);
                expect(unselectedModelCheckbox).not.toBeChecked();
            });
        });

        context("when an instance has tags", function () {
            beforeEach(function () {
                var anInstance = this.view.collection.at(0);
                anInstance.tags().reset([{name: "tag1"}, {name: "tag2"}]);
                this.view.render();
            });

            it("should show a list of tags", function () {
                expect(this.view.$('.item_tag_list')).toContainTranslation("tag_list.title");
                expect(this.view.$('.item_tag_list')).toContainText("tag1 tag2");
            });

            it("tags should link to the tag show page", function () {
                expect(this.view.$(".item_tag_list a:contains(tag1)").attr("href")).toEqual("#/tags/tag1");
            });

        });
    });
});
