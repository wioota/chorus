describe("chorus.views.DataTabDataset", function() {
    beforeEach(function() {
        this.dataset = rspecFixtures.dataset({ schema: { name: "schema_name"}, objectName: "1234",  entitySubtype: "SANDBOX_TABLE", objectType: "TABLE" });
        this.view = new chorus.views.DataTabDataset({model: this.dataset});
        this.qtip = stubQtip();
        this.view.render();
        spyOn(chorus.PageEvents, "broadcast");
    });

    it("adds the correct data attribute for fullname", function() {
        expect(this.view.$el.data("fullname")).toBe('schema_name."1234"');
    });

    it("renders the appropriate icon", function() {
        expect(this.view.$("img:eq(1)")).toHaveAttr("src", "/images/sandbox_table_small.png");
        this.view.model.set("objectType", "VIEW");
        this.view.render();
        expect(this.view.$("img:eq(1)")).toHaveAttr("src", "/images/sandbox_view_small.png");
    });

    it("renders the name of the dataset", function() {
        expect(this.view.$(".name")).toContainText("1234");
    });

    context("when hovering over an li", function () {
        beforeEach(function () {
            this.view.$el.mouseenter();
        });

        it("has the insert text in the insert arrow", function () {
            expect(this.qtip.find("a")).toContainTranslation('database.sidebar.insert');
        });

        context("when clicking the insert arrow", function () {
            beforeEach(function () {
                this.qtip.find("a").click();
            });

            it("broadcasts a file:insertText with the string representation", function () {
                expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith("file:insertText", this.dataset.toText());
            });
        });

        context("when clicking the name link within the li", function () {
            beforeEach(function () {
                spyOn(jQuery.Event.prototype, 'preventDefault');
                this.view.$('.name a').click();
            });

            it("prevents the click from causing a navigation", function() {
                expect(jQuery.Event.prototype.preventDefault).toHaveBeenCalled();
            });
        });

        context("when clicking the toggle_visibility arrow", function () {
            beforeEach(function () {
                this.view.$('.toggle_visibility').click();
                this.server.completeFetchAllFor(this.dataset.columns(), [
                    rspecFixtures.databaseColumn({name: "column_1"})
                ]);
            });

            it("shows the columns", function() {
                expect(this.view.$(".data_tab_dataset_column_list")).toContainText("column_1");
            });
        });
    });
});