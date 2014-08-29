describe("chorus.views.DashboardWorkspaceActivity", function() {
    beforeEach(function() {
        this.view = new chorus.views.DashboardWorkspaceActivity();
        this.workspaceActivity = backboneFixtures.dashboard.workspaceActivity().attributes;
    });

    describe("setup", function() {
        it("fetches the activity data", function() {
            expect(this.server.lastFetch().url).toBe('/dashboards?entity_type=workspace_activity');
        });

        context("when the fetch completes", function() {
            beforeEach(function() {
                this.server.lastFetch().respondJson(200, this.workspaceActivity);
            });

            it("has the title", function() {
                expect(this.view.$(".title")).toContainTranslation("dashboard.workspace_activity.name");
            });

            it("displays the chart", function() {
                expect(this.view.$(".chart")).toExist();
            });
        });
    });
});
