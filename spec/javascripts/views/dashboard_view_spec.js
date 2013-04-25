describe("chorus.views.Dashboard", function(){
    beforeEach(function(){
        var workspaceSet = new chorus.collections.WorkspaceSet();
        var dataSourceSet = new chorus.collections.DataSourceSet();
        this.view = new chorus.views.Dashboard({ collection: workspaceSet, dataSourceSet: dataSourceSet });
        this.activities = new chorus.collections.ActivitySet([]);
    });

    describe("#setup", function() {
        it("fetches the dashboard activities", function() {
            expect(this.activities).toHaveBeenFetched();
        });

        it("sets page size information on the activity list", function() {
            expect(this.view.activityList.collection.attributes.pageSize).toBe(50);
        });

        it("doesnt re-fetch the activity list if a comment is added", function() {
            this.server.reset();
            chorus.PageEvents.trigger("comment:added");
            expect(this.activities).not.toHaveBeenFetched();
        });

        it("doesnt re-fetch the activity list if a comment is deleted", function() {
            this.server.reset();
            chorus.PageEvents.trigger("comment:deleted");
            expect(this.activities).not.toHaveBeenFetched();
        });
    });

    describe("#render", function() {
        beforeEach(function () {
            this.view.render();
        });

        describe("the header", function() {
            beforeEach(function() {
                this.headerView = this.view.dashboardMain.contentHeader;
            });

            it("is an ActivityListHeader view", function() {
                expect(this.headerView).toBeA(chorus.views.ActivityListHeader);
            });

            it("has the right titles for both 'all' and 'insights' modes", function() {
                expect(this.headerView.options.allTitle).toMatchTranslation("dashboard.title.activity");
                expect(this.headerView.options.insightsTitle).toMatchTranslation("dashboard.title.insights");
            });
        });

        describe("the workspace list", function(){
            it("renders the workspace list with the right title", function() {
                expect(this.view.$(".main_content.workspace_list .content_header h1").text()).toMatchTranslation("header.my_workspaces");
            });

            it("has a create workspace link in the content details", function() {
                expect(this.view.$(".workspace_list .content_details [data-dialog=WorkspacesNew]")).toExist();
            });

            it("has a 'browse all' link in the content details", function() {
                var browseAllLink = this.view.$(".main_content.workspace_list .content_details a[href='#/workspaces']");
                expect(browseAllLink).toExist();
                expect(browseAllLink.text()).toMatchTranslation("dashboard.workspaces.browse_all");
            });
        });

        describe('the data source list', function() {
            it('renders the data source list with the right title', function() {
                expect(this.view.$(".main_content.data_source_list .content_header h1").text()).toMatchTranslation("header.browse_data");
            });

            it("has a 'browse all' link in the content details", function() {
                var browseLink = this.view.$(".dashboard_data_source_list_content_details a.browse_all");
                expect(browseLink.text().trim()).toMatchTranslation("dashboard.data_sources.browse_all");
                expect(browseLink.attr("href")).toBe("#/data_sources");
            });

            it('has the Add a Data Source link', function() {
                var link = this.view.$(".dashboard_data_source_list_content_details a.add");
                expect(link.text().trim()).toMatchTranslation("dashboard.data_sources.add");
                expect(link.data("dialog")).toBe("DataSourcesNew");
            });
        });

        it("has an activity list", function() {
            expect(this.view.$(".activity_list")).toExist();
        });
    });
});
