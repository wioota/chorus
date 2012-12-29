describe("chorus.views.TagListSidebar", function() {
    beforeEach(function() {
        this.tags = new chorus.collections.TagSet([{name: "Hello"}]);
        this.view = new chorus.views.TagListSidebar();
    });

    it("displays the tag name selected on the page", function() {
        chorus.PageEvents.broadcast('tag:selected', this.tags.first());
        expect(this.view.$el).toContainText('Hello');
    });
});