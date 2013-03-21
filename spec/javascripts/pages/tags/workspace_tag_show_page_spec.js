describe("chorus.pages.WorkspaceTagShowPage", function() {
    var tag, page, workspace;
    beforeEach(function() {
        workspace = rspecFixtures.workspace({id: 101});
        tag = new chorus.models.Tag({name: "tag-name"});
        page = new chorus.pages.WorkspaceTagShowPage(workspace.id, "this_workspace", "all", tag.name());
    });

    describe("breadcrumbs", function() {
        beforeEach(function() {
            this.server.completeFetchFor(page.search, { thisWorkspace: { docs: [], numFound: 0 }});
            this.server.completeFetchFor(page.search.workspace(), { id: "101", name: "Bob the workspace" });
        });

        it("displays the Tags breadcrumb", function() {
            var breadcrumbs = page.$("#breadcrumbs .breadcrumb a");

            expect(breadcrumbs.eq(0).attr("href")).toBe("#/");
            expect(breadcrumbs.eq(0).text()).toBe(t("breadcrumbs.home"));

            expect(breadcrumbs.eq(1).attr("href")).toBe("#/tags");
            expect(breadcrumbs.eq(1).text()).toBe(t("breadcrumbs.tags"));

            expect(page.$("#breadcrumbs .breadcrumb .slug")).toContainText(tag.name());
        });
    });

    it("searches tags", function() {
        expect(page.search.get("isTag")).toBeTruthy();
    });

    it("fetches the workspace", function() {
        expect(page.search.workspace()).toHaveBeenFetched();
    });

    it("has no required resources", function() {
        expect(page.requiredResources.length).toBe(0);
    });

    describe("when the workspace and tagged objects are fetched", function() {
        context("when the search is scoped", function() {
            beforeEach(function() {
                this.server.completeFetchFor(page.search, { thisWorkspace: { docs: [], numFound: 0 }});
                this.server.completeFetchFor(page.search.workspace(), { id: "101", name: "Bob the workspace" });
            });

            xit("includes the workspace in the breadcrumbs", function() {
                var crumbs = page.$("#breadcrumbs li");
                expect(crumbs.length).toBe(3);
                expect(crumbs.eq(0)).toContainTranslation("breadcrumbs.home");
                expect(crumbs.eq(1).text().trim()).toBe("Bob the workspace");
                expect(crumbs.eq(1).find("a")).toHaveHref(page.search.workspace().showUrl());
                expect(crumbs.eq(2)).toContainTranslation("breadcrumbs.search_results");
            });

            it("disables the 'data sources', 'people', 'hdfs entries' and 'workspaces' options in the filter menu", function() {
                var menuOptions = page.$(".default_content_header .link_menu.type li");
                expect(menuOptions.find("a").length).toBe(3);

                expect(menuOptions.filter("[data-type=data_source]")).not.toContain("a");
                expect(menuOptions.filter("[data-type=user]")).not.toContain("a");
                expect(menuOptions.filter("[data-type=workspace]")).not.toContain("a");
                expect(menuOptions.filter("[data-type=hdfs_entry]")).not.toContain("a");
                expect(menuOptions.filter("[data-type=attachment]")).not.toContain("a");

                expect(menuOptions.filter("[data-type=workfile]")).toContain("a");
                expect(menuOptions.filter("[data-type=dataset]")).toContain("a");
                expect(menuOptions.filter("[data-type=all]")).toContain("a");
            });

            it("has the 'this workspace' option in the 'Search in' menu", function() {
                var searchInMenu = page.$(".default_content_header .search_in");
                var searchInOptions = searchInMenu.find(".menu li");

                expect(searchInOptions.length).toBe(3);
                expect(searchInOptions).toContainTranslation("search.in.all");
                expect(searchInOptions).toContainTranslation("search.in.my_workspaces");
                expect(searchInOptions).toContainTranslation("search.in.this_workspace", { workspaceName: "Bob the workspace" });
                expect(searchInMenu.find(".chosen")).toContainTranslation("search.in.this_workspace", { workspaceName: "Bob the workspace" });
            });
        });

        context("when searching all of chorus", function() {
            beforeEach(function() {
                this.server.reset();
                page = new chorus.pages.WorkspaceTagShowPage(workspace.id, this.query);
                this.server.completeFetchFor(page.search, { thisWorkspace: { docs: [], numFound: 0 }});
                this.server.completeFetchFor(page.search.workspace(), { id: "101", name: "Bob the workspace" });
            });

            it("enables all options in the filter menu", function() {
                var menuOptions = page.$(".default_content_header li");

                expect(menuOptions.filter("[data-type=data_source]")).toContain("a");
                expect(menuOptions.filter("[data-type=user]")).toContain("a");
                expect(menuOptions.filter("[data-type=workspace]")).toContain("a");
                expect(menuOptions.filter("[data-type=hdfs_entry]")).toContain("a");
                expect(menuOptions.filter("[data-type=workfile]")).toContain("a");
                expect(menuOptions.filter("[data-type=dataset]")).toContain("a");
                expect(menuOptions.filter("[data-type=all]")).toContain("a");
            });
        });

        context("called resourcesLoaded only when both workspace and search fetches completes", function () {
            beforeEach(function () {
                this.server.completeFetchFor(page.search.workspace(), { id: "101", name: "Bob the workspace" });
            });

            it("doesn't create mainContentView", function () {
                expect(page.mainContent).toBeUndefined();
            });

            it("includes a section for every type of item when both fetches completes", function() {
                this.server.completeFetchFor(page.search, rspecFixtures.searchResult());

                var sections = page.$(".search_result_list ul");
                expect(sections.filter(".user_list.selectable")).toExist();
                expect(sections.filter(".workfile_list.selectable")).toExist();
                expect(sections.filter(".attachment_list.selectable")).toExist();
                expect(sections.filter(".workspace_list.selectable")).toExist();
                expect(sections.filter(".hdfs_entry_list.selectable")).toExist();
                expect(sections.filter(".data_source_list.selectable")).toExist();
            });

        });
    });

    it("sets the workspace id, for prioritizing search", function() {
        expect(page.workspaceId).toBe(101);
    });
});
