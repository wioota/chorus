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
            expect(this.view.$('li[data-id]').length).toBeGreaterThan(0);

            _.each(this.tags.models, function(tag) {
                var element = this.view.$('li[data-id=' + tag.get('id') + ']');
                expect(element).toContainText(tag.get('name'));
                expect(element.find('a').attr("href")).toEqual('#/tags/' + tag.name());
                expect(element).toContainText(tag.get('count') + " items");
            }, this);
        });

        describe("when the tag name has special characters", function() {
            beforeEach(function() {
                this.tags.reset({ name: '!@#$%^&*()"', id: 1234 }, { silent: true });
                this.tags.trigger('loaded');
            });

            it('uri encodes the url', function() {
                expect(this.view.$('li[data-id=1234] a').attr("href")).toEqual('#/tags/!%40%23%24%25%5E%26*()%22');
            });
        });

        context("when there are no tags", function() {
            it("should render text to tell the user", function() {
               this.view.collection = new chorus.collections.TagSet();
               this.view.render();

               expect(this.view.$el).toContainTranslation('tags.none');
            });
        });
    });

    describe("when a tag is deleted", function() {
        beforeEach(function() {
            this.view.render();

            this.tag = this.tags.first();
            this.tagId = this.tag.id;
            this.tag.destroy();
            this.server.completeDestroyFor(this.tag);
            expect(this.tags.length).toBeGreaterThan(0);
            expect(this.tags.pluck('name')).not.toContain(this.tag.get('name'));
        });

        it("should re-render", function() {
            expect(this.view.$('li[data-id=' + this.tagId + ']')).not.toExist();
            this.tags.each(function(tag) {
                var element = this.view.$('li[data-id=' + tag.get('id') + ']');
                expect(element).toContainText(tag.get('name'));
                expect(element).toContainText(tag.get('count') + " items");
            }, this);
        });
    });
});