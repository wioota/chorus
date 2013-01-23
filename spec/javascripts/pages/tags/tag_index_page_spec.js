describe("chorus.pages.TagIndexPage", function() {
    beforeEach(function() {
        this.page = new chorus.pages.TagIndexPage();
        this.tagSet = new chorus.collections.TagSet();
    });

    describe("breadcrumbs", function() {
        beforeEach(function() {
            this.page.render();
        });

        it("displays the Tags breadcrumb", function() {
            expect(this.page.$('.breadcrumbs')).toContainTranslation("breadcrumbs.home");
            expect(this.page.$('.breadcrumbs')).toContainTranslation("breadcrumbs.tags");
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.page.render();
        });

        it('displays the page title', function() {
            expect(this.page.$('h1[title=Tags]')).toContainTranslation("tags.title_plural");
        });
    });

    describe("when the tags have loaded", function() {
        beforeEach(function() {
            this.tags = [{ name: "IamTag"}, { name: "IamAlsoTag" }];
            this.server.completeFetchAllFor(this.tagSet, this.tags);
        });

        it("displays the tags", function() {
            _.each(this.tags, function(tag) {
                expect(this.page.$('.content')).toContainText(tag.name);
            }, this);
        });

        it("loads the correct count", function() {
            expect(this.page.$('.count')).toContainText(this.tags.length);
        });

        describe("sidebar", function() {
            it("selects the first tag and shows it on the sidebar", function() {
                expect(this.page.$('.tag_title')).toContainText("IamTag");
            });
        });
    });
});
