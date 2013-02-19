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

    it("is empty if no tag is select", function() {
        chorus.PageEvents.broadcast('tag:selected', this.selectedTag);
        chorus.PageEvents.broadcast('tag:deselected');
        expect(this.view.$el.html().trim()).toEqual('');
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

    describe("rename tag link", function() {
        beforeEach(function() {
            setLoggedInUser({admin: false}, chorus);
            chorus.PageEvents.broadcast('tag:selected', this.selectedTag);
            this.renameLink = this.view.$el.find(".actions a.rename_tag_link");
        });

        it("does not display the rename tag link", function() {
            expect(this.renameLink).toExist();
            expect(this.renameLink).toContainTranslation("tag_list.rename.button");
        });

        context("clicking rename tag", function() {
           beforeEach(function() {
               spyOn(this.view.renameTagDialog, "launchModal");
               this.renameLink.click();
           });

           it("opens the rename tag dialog", function() {
               expect(this.view.renameTagDialog.model).toBe(this.selectedTag);
               expect(this.view.renameTagDialog.launchModal).toHaveBeenCalled();
           });
        });
    });
});