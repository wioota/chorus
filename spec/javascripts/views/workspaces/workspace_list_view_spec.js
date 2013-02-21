describe("chorus.views.WorkspaceList", function() {
    beforeEach(function() {
        this.activeWorkspace = new chorus.models.Workspace({id: 1, archivedAt: null, name: "my active workspace", tags:[{name: "tag"}]});

        this.archivedWorkspace = new chorus.models.Workspace({
            id: 2,
            archivedAt: Date.formatForApi((2).hours().ago()),
            name: "my archived workspace",
            archiver: { firstName: "John", lastName :"Henry"},
            summary: " this is an archived workspace"
        });

        this.publicWorkspace = new chorus.models.Workspace({id: 4, "public": true, name: "my public workspace"});
        this.privateWorkspace = new chorus.models.Workspace({
            id: 3,
            "public": false,
            archivedAt: null,
            ownerFirstName: "Dr",
            ownerLastName: "Mario",
            name: "my private workspace"
        });

        this.archivedBigSummaryWorkspace = new chorus.models.Workspace({
            id: 5,
            archivedAt: "2012-05-08T21:40:14Z",
            name: "my archived workspace",
            archiverFirstName: "John",
            archiverLastName: "Henry",
            summary: "this is an archived big summary workspace this is an big summary archived workspace this is an archived workspace this is an archived workspace " +
                "this is an archived workspace this is an archived workspace this is an archived workspace this is an archived workspace this is an archived workspace"
        });

        this.collection = new chorus.collections.WorkspaceSet();

        this.view = new chorus.views.WorkspaceList({collection: this.collection});
    });

    describe("when the workspaces have loaded", function() {
        beforeEach(function() {
            this.collection.fetchAll();
            this.server.completeFetchAllFor(this.collection, [
                this.activeWorkspace.attributes,
                this.archivedWorkspace.attributes,
                this.privateWorkspace.attributes,
                this.publicWorkspace.attributes,
                this.archivedBigSummaryWorkspace.attributes
            ]);

            this.activeEl = this.view.$("li[data-id=1]");
            this.archivedEl = this.view.$("li[data-id=2]");
            this.privateEl = this.view.$("li[data-id=3]");
            this.publicEl = this.view.$("li[data-id=4]");
        });

        it("has class selectable", function() {
            expect($(this.view.el)).toHaveClass("selectable");
        });

        it("displays all the workspaces", function() {
            expect(this.view.$("li").length).toBe(5);
        });

        it("sets title attributes for the workspace names", function() {
            var self = this;

            _.each(this.view.$("a.name span"), function(el, index) {
                expect($(el).attr("title")).toBe(self.collection.at(index).get("name"));
            });
        });

        it("links the workspace name to the show url", function() {
            expect($("a.name span", this.activeEl).text().trim()).toBe(this.activeWorkspace.get("name"));
            expect($("a.name", this.activeEl).attr("href")).toBe(this.activeWorkspace.showUrl());
        });

        it("indicates which workspaces are private", function() {
            expect(this.privateEl.text()).toContain(t("workspaces.private"));
            expect(this.publicEl.text()).not.toContain(t("workspaces.private"));

            expect($("img[src='/images/workspace-lock.png']", this.privateEl)).toExist();
            expect($("img[src='/images/workspace-lock.png']", this.publicEl)).not.toExist();
        });

        it("includes the owner's name", function() {
            expect($(".owner", this.privateEl).text()).toContain(this.privateWorkspace.owner().displayName());
        });

        it("links to the owner's profile", function() {
            expect($(".owner a", this.privateEl).attr('href')).toBe(this.privateWorkspace.owner().showUrl());
        });

        it("displays the truncated text view", function() {
            expect(this.view.$(".truncated_text").length).toBe(5);
        });

        it("shows the workspace's tags", function() {
           expect(this.activeEl.find(".item_tag_list")).toContainText("tag");
        });

        describe("archived workspace", function() {
            it("displays the active workspace icon for the active workspace", function() {
                expect(this.view.$("li[data-id=1] img").attr("src")).toBe(this.activeWorkspace.defaultIconUrl());
            });

            it("displays the archived workspace icon for the archived workspace", function() {
                expect($("img", this.archivedEl).attr("src")).toBe(this.archivedWorkspace.defaultIconUrl());
            });

            it("displays the archiver FullName for the archived workspace", function() {
                expect($(".owner a", this.archivedEl).text()).toContain(this.archivedWorkspace.archiver().displayName());
            });

            it("links to the archiver's profile", function() {
                expect($(".owner a", this.archivedEl).attr('href')).toBe(this.archivedWorkspace.archiver().showUrl());
            });

            it("displays archived relative time", function() {
                expect($(".timestamp", this.view.$("li[data-id=2]")).text()).toBe("2 hours ago");
            });
        });

        it("skips rendering of child views from CheckableList", function() {
            expect(this.view.liViews).toBeUndefined();
            expect(this.view.$("> li").eq(this.view.selectedIndex)).toHaveClass("selected");
        });
    });
});
