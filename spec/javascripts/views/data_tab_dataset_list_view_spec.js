describe("chorus.views.DataTabDatasetList", function() {
    beforeEach(function() {
        spyOn(chorus.PageEvents, "broadcast").andCallThrough();
        this.collection = new chorus.collections.DatasetSet([
            rspecFixtures.dataset({ schema: { name: "schema_name"}, objectName: "1234",  entitySubtype: "SANDBOX_TABLE", objectType: "TABLE" }),
            rspecFixtures.dataset({ schema: { name: "schema_name"}, objectName: "Data1", entitySubtype: "SANDBOX_TABLE", objectType: "VIEW" }),
            rspecFixtures.dataset({ schema: { name: "schema_name"}, objectName: "Data2", entitySubtype: "SANDBOX_TABLE", objectType: "TABLE" }),
            rspecFixtures.dataset({ schema: { name: "schema_name"}, objectName: "zebra", entitySubtype: "SANDBOX_TABLE", objectType: "VIEW" })
        ]);
        this.view = new chorus.views.DataTabDatasetList({collection: this.collection});
        this.view.render();
    });

    it("displays a loading section", function() {
        expect(this.view.$(".loading_section")).toExist();
    });

    context("when the collection is loaded", function() {
        beforeEach(function() {
            this.collection.loaded = true;
            this.collection.trigger('reset');
        });

        it("renders an li for each item in the list", function() {
            expect(this.view.$("li").length).toBe(4);
        });

        describe("pagination", function() {
            beforeEach(function() {
                this.collection.reset([
                    rspecFixtures.dataset({objectName: "Table 1"}),
                    rspecFixtures.dataset({objectName: "Table 2"})
                ]);
            });

            context("when there is more than one page of results", function() {
                beforeEach(function() {
                    this.collection.pagination = { page: "1", total: "2" };
                    this.view.render();
                });

                it("shows the more link", function() {
                    expect(this.view.$("a.more")).toContainTranslation("schema.metadata.more");
                });

                context("when the more link is clicked", function() {
                    beforeEach(function() {
                        spyOnEvent(this.view, "fetch:more");
                        this.view.$("a.more").click();
                    });

                    it("triggers a 'fetch:more event on itself", function() {
                        expect("fetch:more").toHaveBeenTriggeredOn(this.view);
                    });
                });

                context("after additional models are added to the collection", function() {
                    beforeEach(function() {
                        this.originalViews = this.view.datasetViews;
                        this.collection.add(rspecFixtures.dataset({objectName: "Table 3"}));
                    });

                    it('does not regenerate subviews immediately', function() {
                        expect(this.view.datasetViews).toEqual(this.originalViews);
                        expect(this.view.$('li').length).toBe(2);
                    });

                    it('regenerates the dataset subviews', function() {
                        this.view.render();
                        expect(this.view.$('li').length).toBe(3);
                    });
                });
            });

            context("when there is only one page of results", function() {
                beforeEach(function() {
                    this.collection.pagination = { page: "1", total: "1" };
                    this.view.render();
                });

                it("doesn't show the more link", function() {
                    expect(this.view.$("a.more")).not.toExist();
                });
            });
        });

        it("does not destroy/regenerate subviews on render", function() {
            var originalViews = this.view.datasetViews;
            this.view.render();
            expect(this.view.datasetViews).toEqual(originalViews);
        });
    });
});
