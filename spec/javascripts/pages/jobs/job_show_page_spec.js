describe("chorus.pages.JobsShowPage", function () {
    beforeEach(function () {
        this.model = backboneFixtures.job();
        this.workspace = this.model.workspace();
        this.page = new chorus.pages.JobsShowPage(this.workspace.id, this.model.get('id'));
    });

    it("should have the right constructor name", function () {
        expect(this.page.constructorName).toBe("JobsShowPage");
    });

    context("after the fetch completes", function () {
        beforeEach(function() {
            this.server.completeFetchFor(this.model);
        });

        it("should create the subnav on the jobs tab", function () {
            expect(this.page.subNav).toBeA(chorus.views.SubNav);
        });

        it("creates main content", function () {
            expect(this.page.mainContent).toBeA(chorus.views.MainContentList);
        });

        it("displays the Job's name in the header", function () {
            var header = this.page.mainContent.contentHeader.$("h1");
            expect(header).toContainText(this.model.get('name'));
        });

        it("creates the correct buttons", function() {
            expect(this.page.mainContent.contentDetails.buttonView).toBeA(chorus.views.JobShowPageButtons);
            expect(this.page.mainContent.contentDetails.buttonView.model.get("id")).toBe(this.model.get("id"));
        });

        describe("breadcrumbs", function() {
            it("renders home > Workspaces > {workspace name} > Jobs", function() {
                expect(this.page.$(".breadcrumb:eq(0) a").attr("href")).toBe("#/");
                expect(this.page.$(".breadcrumb:eq(0) a").text()).toMatchTranslation("breadcrumbs.home");

                expect(this.page.$(".breadcrumb:eq(1) a").attr("href")).toBe("#/workspaces");
                expect(this.page.$(".breadcrumb:eq(1) a").text()).toMatchTranslation("breadcrumbs.workspaces");

                expect(this.page.$(".breadcrumb:eq(2) a").attr("href")).toBe("#/workspaces/" + this.workspace.id);
                expect(this.page.$(".breadcrumb:eq(2) a").text()).toBe(this.workspace.get("name"));

                expect(this.page.$(".breadcrumb:eq(3)").text().trim()).toMatchTranslation("breadcrumbs.jobs");

                expect(this.page.$(".breadcrumb:eq(4)").text().trim()).toBe(this.model.get("name"));
            });
        });
    });
});