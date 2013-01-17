describe("chorus.views.TagListSidebar", function() {
    beforeEach(function() {
        this.tags = new chorus.collections.TagSet([{name: "Hello"}]);
        this.view = new chorus.views.TagListSidebar();
        this.selectedTag = this.tags.first();
    });

    it("displays the tag name selected on the page", function() {
        chorus.PageEvents.broadcast('tag:selected', this.selectedTag);
        expect(this.view.$el).toContainText('Hello');
    });

    describe("delete tag link", function() {
        context("user is admin", function() {
            beforeEach(function() {
                setLoggedInUser({admin: true}, chorus);
                chorus.PageEvents.broadcast('tag:selected', this.selectedTag);
                this.deleteLink = this.view.$(".actions a.delete_tag_link");
            });

            it("displays the delete tag link", function() {
                expect(this.deleteLink).toExist();
                expect(this.deleteLink).toContainTranslation('tag_list.delete.button');
            });
        });

        context("user is not admin", function() {
            beforeEach(function() {
                setLoggedInUser({admin: false}, chorus);
                chorus.PageEvents.broadcast('tag:selected', this.selectedTag);
                this.deleteLink = this.view.$el.find(".actions a.delete_tag_link");
            });

            it("does not display the delete tag link", function() {
                expect(this.deleteLink).not.toExist();
            });
        });

    });
});