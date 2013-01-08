describe("chorus.views.TagList", function() {
    beforeEach(function() {
        this.tags = rspecFixtures.tagSet();
        this.view = new chorus.views.TagList({
            collection: this.tags
        });
    });

    it("has the correct eventName", function() {
        expect(this.view.eventName).toBe("tag");
    });

    describe("loading", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("requires a tags set", function() {
            this.tags.reset({ name: "NewTag" }, { silent: true });
            this.tags.trigger('loaded');

            _.each(this.tags.models, function(tag) {
                expect(this.view.$el).toContainText(tag.name());
            }, this);
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("should display all the tags", function() {
            _.each(this.tags.models, function(tag) {
                var element = this.view.$('li[data-id=' + tag.get('id') + ']');
                expect(element).toContainText(tag.get('name'));
                expect(element).toContainText(tag.get('count') + " items");
            }, this);
        });

        context("when there are no tags", function() {
            it("should render text to tell the user", function() {
               this.view.collection = new chorus.collections.TagSet();
               this.view.render();

               expect(this.view.$el).toContainTranslation('tags.none');
            });
        });
    });
});