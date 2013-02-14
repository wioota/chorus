describe("chorus.views.DataTabDataset", function() {
    beforeEach(function() {
        this.dataset = rspecFixtures.dataset({ schema: { name: "schema_name"}, objectName: "1234",  entitySubtype: "SANDBOX_TABLE", objectType: "TABLE" });
        this.view = new chorus.views.DataTabDataset({model: this.dataset});
        this.view.render();
    });

    it("adds the correct data attribute for fullname", function() {
        expect(this.view.$el.data("fullname")).toBe('schema_name."1234"');
    });

    it("renders the appropriate icon", function() {
        expect(this.view.$("img")).toHaveAttr("src", "/images/sandbox_table_small.png");
        this.view.model.set("objectType", "VIEW");
        this.view.render();
        expect(this.view.$("img")).toHaveAttr("src", "/images/sandbox_view_small.png");
    });

    it("renders the name of the dataset", function() {
        expect(this.view.$(".name")).toContainText("1234");
    });
});