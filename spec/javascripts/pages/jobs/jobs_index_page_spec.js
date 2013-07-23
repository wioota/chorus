describe("chorus.pages.JobsIndexPage", function () {
    beforeEach(function () {
        this.workspace = backboneFixtures.workspace();
        this.page = new chorus.pages.JobsIndexPage(this.workspace.id);
    });

    it("should have the right constructor name", function () {
       expect(this.page.constructorName).toBe("JobsIndexPage");
    });

    describe("breadcrumbs", function() {
        beforeEach(function() {
            this.workspace.set({name: "Cool Workspace"});
            this.server.completeFetchFor(this.workspace);
            this.page.render();
        });

        it("renders home > Workspaces > {workspace name} > Jobs", function() {
            expect(this.page.$(".breadcrumb:eq(0) a").attr("href")).toBe("#/");
            expect(this.page.$(".breadcrumb:eq(0) a").text()).toMatchTranslation("breadcrumbs.home");

            expect(this.page.$(".breadcrumb:eq(1) a").attr("href")).toBe("#/workspaces");
            expect(this.page.$(".breadcrumb:eq(1) a").text()).toMatchTranslation("breadcrumbs.workspaces");

            expect(this.page.$(".breadcrumb:eq(2) a").attr("href")).toBe("#/workspaces/" + this.workspace.id);
            expect(this.page.$(".breadcrumb:eq(2) a").text()).toBe("Cool Workspace");

            expect(this.page.$(".breadcrumb:eq(3)").text().trim()).toMatchTranslation("breadcrumbs.jobs");
        });
    });

    describe("subnav", function () {
        it("should create the subnav on the jobs tab", function () {
            expect(this.page.subNav).toBeA(chorus.views.SubNav);
        });
    });
    
    describe("#setup", function () {
        it("creates main content", function () {
            expect(this.page.mainContent).toBeA(chorus.views.MainContentList);
        });

        it("creates the correct buttons", function() {
            expect(this.page.mainContent.contentDetails.buttonView).toBeA(chorus.views.JobIndexPageButtons);
            expect(this.page.mainContent.contentDetails.buttonView.model.get("id")).toBe(this.workspace.get("id"));
        });
    });
});