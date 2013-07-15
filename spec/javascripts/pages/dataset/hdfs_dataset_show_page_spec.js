describe("chorus.pages.HdfsDatasetShowPage", function () {
    beforeEach(function () {
        this.dataset = backboneFixtures.workspaceDataset.hdfsDataset();
        this.dataset.set("content", ["hello, from, hadoop"]);
        this.workspace = this.dataset.workspace();
        this.datasetId = this.dataset.get('id');

        this.page = new chorus.pages.HdfsDatasetShowPage(this.workspace.get("id"), this.datasetId);
    });

    describe("#initialize", function () {
        it("constructs an hdfs dataset with the right id", function () {
            expect(this.page.model).toBeA(chorus.models.HdfsDataset);
            expect(this.page.model.get("id")).toBe(this.datasetId);
        });

        it("has a helpId", function() {
            expect(this.page.helpId).toBe("dataset");
        });
    });

    describe("when the workspace and dataset fetches complete", function () {
        beforeEach(function () {
            this.server.completeFetchFor(this.workspace);
            this.server.completeFetchFor(this.dataset);
        });

        describe("breadcrumbs", function() {
            it("links to home for the first crumb", function() {
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(0).attr("href")).toBe("#/");
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(0).text()).toBe(t("breadcrumbs.home"));
            });

            it("links to /workspaces for the second crumb", function() {
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(1).attr("href")).toBe("#/workspaces");
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(1).text()).toBe(t("breadcrumbs.workspaces"));
            });

            it("links to workspace show for the third crumb", function() {
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(2).attr("href")).toBe(this.workspace.showUrl());
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(2).text()).toBe(this.workspace.displayName());
            });

            it("links to the workspace data tab for the fourth crumb", function() {
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(3).attr("href")).toBe(this.workspace.showUrl() + "/datasets");
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(3).text()).toBe(t("breadcrumbs.workspaces_data"));
            });

            it("displays the object name for the fifth crumb", function() {
                expect(this.page.$("#breadcrumbs .breadcrumb .slug").text()).toBe(this.dataset.name());
            });
        });

        it("shows the dataset content", function() {
            expect(this.page.mainContent.content).toBeA(chorus.views.ReadOnlyTextContent);
            expect(this.page.mainContent.content.model.get('content')).toEqual(this.dataset.get("content"));
        });

        it("shows the DatasetShowContentHeader", function () {
            expect(this.page.mainContent.contentHeader).toBeA(chorus.views.DatasetShowContentHeader);
        });

        it("shows the DatasetShowContentDetails", function () {
            expect(this.page.mainContent.contentDetails).toBeA(chorus.views.HdfsDatasetContentDetails);
        });

        it("sets up the sidebar", function () {
            expect(this.page.sidebar).toBeA(chorus.views.DatasetSidebar);
        });

        it("sets up sidebar activities & statistics", function () {
            expect(this.page.$('.activity_list')).toExist();
            expect(this.page.$('.dataset_statistics')).toExist();
        });

    });

    describe("when the hdfs dataset is invalidated", function() {
        beforeEach(function () {
            this.server.reset();
            this.page.model.trigger("invalidated");
        });

        it("the hdfs dataset should refetch", function() {
            expect(this.page.model).toHaveBeenFetched();
        });
    });
});