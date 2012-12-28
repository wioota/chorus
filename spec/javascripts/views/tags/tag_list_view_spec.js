describe("chorus.views.TagList", function() {
    beforeEach(function() {
        this.tags = new chorus.collections.TagSet([
            {name: "IamTag"},
            {name: "IamAlsoTag"}
        ]);

        this.view = new chorus.views.TagList({
            collection: this.tags
        });
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
                expect(this.view.$el).toContainText(tag.get('name'));
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