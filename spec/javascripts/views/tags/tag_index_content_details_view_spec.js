describe("chorus.views.TagIndexContentDetails", function() {
    beforeEach(function() {
        this.tags = new chorus.collections.TagSet([
            {name: "IamTag"},
            {name: "IamAlsoTag"}
        ]);

        this.view = new chorus.views.TagIndexContentDetails({
            tags: this.tags
        });
    });

    describe("loading", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("requires a tags set", function() {
            this.tags.reset({ name: "NewTag" }, { silent: true });
            this.tags.trigger('loaded');

            expect(this.view.$('.number')).toContainText(this.tags.length);
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("displays the count of tags", function() {
            expect(this.view.$('.number')).toContainText(this.tags.length);
            expect(this.view.$('.count')).toContainTranslation("tags.title_plural");
        });
    });
});