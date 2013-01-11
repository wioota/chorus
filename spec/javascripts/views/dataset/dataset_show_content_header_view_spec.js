describe("chorus.views.DatasetShowContentHeader", function() {
    beforeEach(function() {
        this.model = rspecFixtures.workspaceDataset.sourceTable({
            tags: [{name: "alpha"}]
        });
        this.view = new chorus.views.DatasetShowContentHeader({model: this.model});
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("has tags", function() {
            expect(this.view.$('.text-tags')).toContainText("alpha");
        });
    });
});