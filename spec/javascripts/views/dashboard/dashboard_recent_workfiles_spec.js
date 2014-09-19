describe("chorus.views.DashboardRecentWorkfiles", function() {
    beforeEach(function() {
        this.view = new chorus.views.DashboardRecentWorkfiles();
        this.recentWorkfilesAttrs = backboneFixtures.dashboard.recentWorkfiles().attributes;
    });

    describe("setup", function() {
        it("fetches the recent workfiles data", function() {
            expect(this.server.lastFetch().url).toBe('/dashboards?entity_type=recent_workfiles');
        });

        context("when the fetch completes", function() {
            beforeEach(function() {
                this.server.lastFetch().respondJson(200, this.recentWorkfilesAttrs);
            });

            it("has a title", function() {
                expect(this.view.$('.title')).toContainTranslation("dashboard.recent_workfiles.name");
            });

            it("displays the recent workfiles data", function() {
                expect(this.view.$('li').length).toBe(5);
                _.each(this.view.$('li'), function(element, index) {
                    var dataIndex = this.recentWorkfilesAttrs.data[index];
                    var workfile = new chorus.models.Workfile(dataIndex.workfile);
                    expect($(element).find(".image img").attr("src")).toBe(workfile.iconUrl());
                    expect($(element).find(".workfile_link").attr("href")).toBe(workfile.showUrl());
                    expect($(element).find(".workfile_link")).toContainText(dataIndex.workfile.fileName);
                    expect($(element).find(".workspace_image").attr("src")).toBe(workfile.workspace().defaultIconUrl("small"));
                    expect($(element).find(".workspace_link")).toContainText(dataIndex.workfile.workspace.name);
                    expect($(element).find(".workspace_link").attr("href")).toBe(workfile.workspace().showUrl());
                    expect($(element).find(".time_edited")).toContainText(Handlebars.helpers.relativeTimestamp(dataIndex.lastOpened));
                }, this);
            });
        });
    });
});
