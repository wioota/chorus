describe("chorus.views.WorkspaceSearchResultList", function() {
    beforeEach(function() {
        this.search = rspecFixtures.searchResultInWorkspace({
            thisWorkspace: { numFound: 9 }
        });
        this.search.set({ query: "foo", workspaceId: "10001" });
        this.search.workspace().set({ name: "John the workspace" });
        var workspaceItems = this.search.workspaceItems();
        this.view = new chorus.views.WorkspaceSearchResultList({
            collection: workspaceItems,
            search: this.search
        });
        this.view.render();
    });

    it("passes the workspace id for tag links as an option to the item views", function() {
        expect(this.view.list.liViews[0].options.workspaceIdForTagLink).toBe("10001");
    });

    it("renders the right type of search result view for each result item", function() {
        var listItems = this.view.$("li");
        expect(this.view.$("li.search_workfile")).toExist();
        expect(this.view.$("li.search_dataset")).toExist();
        expect(this.view.$("li.search_workspace")).toExist();
    });

    it("has the right title", function() {
        expect(this.view.$(".title").text()).toMatchTranslation("search.type.this_workspace", { name: "John the workspace" });
    });

    describe("#clicking 'show all'", function() {
        beforeEach(function() {
            spyOn(chorus.router, 'navigate');
            this.view.$("a.show_all").click();
        });

        it("navigates to the 'this workspace' search page", function() {
            expect(this.view.search.searchIn()).toBe("this_workspace");
            expect(chorus.router.navigate).toHaveBeenCalledWith(this.view.search.showUrl());
        });
    });
});

