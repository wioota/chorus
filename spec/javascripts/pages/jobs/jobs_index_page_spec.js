describe("chorus.pages.JobsIndexPage", function () {
    beforeEach(function () {
        this.model = backboneFixtures.job();
        this.clock = this.useFakeTimers();
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

        it("fetches the collection", function() {
            expect(this.page.collection).toHaveBeenFetched();
        });

        it("defaults to alphabetical sorting ascending", function() {
            expect(this.page.collection.order).toBe("name");
        });

        it("creates the correct buttons", function() {
            expect(this.page.mainContent.contentDetails.buttonView).toBeA(chorus.views.JobsIndexPageButtons);
            expect(this.page.mainContent.contentDetails.buttonView.model.get("id")).toBe(this.workspace.get("id"));
        });

        it("passes the multiSelect option to the list content details", function() {
            expect(this.page.mainContent.contentDetails.options.multiSelect).toBeTruthy();
            expect(this.page.multiSelectSidebarMenu).toBeTruthy();
        });
    });

    describe("when the job:selected event is triggered on the list view", function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.workspace);
            this.page.render();
            chorus.PageEvents.trigger("job:selected", this.model);
        });

        it('instantiates the sidebar view', function() {
            expect(this.page.sidebar).toBeDefined();
            expect(this.page.sidebar).toBeA(chorus.views.JobSidebar);
            expect(this.page.$("#sidebar .sidebar_content.primary")).not.toBeEmpty();
        });

        describe("when job:selected event is triggered and there is already a sidebar", function() {
            beforeEach(function() {
                this.oldSidebar = this.page.sidebar;
                spyOn(this.page.sidebar, 'teardown');
                chorus.PageEvents.trigger("job:selected", this.model);
            });

            it("tears down the old sidebar", function() {
                expect(this.oldSidebar.teardown).toHaveBeenCalled();
            });
        });
    });

    describe("search", function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.workspace);
            this.collection = backboneFixtures.jobSet();
            this.server.completeFetchFor(this.page.collection, [this.collection.at(0), this.collection.at(1)]);

        });

        it("sets up search correctly", function() {
            expect(this.page.$(".list_content_details .count")).toContainTranslation("entity.name.Job", {count: 2});
            expect(this.page.$("input.search")).toHaveAttr("placeholder", t("job.search_placeholder"));

            this.page.$("input.search").val(this.collection.at(0).get("name")).trigger("keyup");

            expect(this.page.$("li.item_wrapper:eq(1)")).toHaveClass("hidden");
            expect(this.page.$(".list_content_details .count")).toContainTranslation("entity.name.Job", {count: 1});
            expect(this.page.mainContent.options.search.eventName).toBe("job:search");
        });

        it("should deselect all on search", function() {
            spyOnEvent(chorus.PageEvents, "selectNone");
            this.page.$("input.search").val("bar").trigger("keyup");
            expect("selectNone").toHaveBeenTriggeredOn(chorus.PageEvents);
        });
    });

    describe("the Sidebar", function () {
        beforeEach(function () {
            var jobs = [backboneFixtures.job()];
            this.server.completeFetchFor(this.page.collection, jobs);
            this.server.completeFetchFor(this.workspace);
            this.page.render();

            this.jobs = this.page.collection.models;
        });

        describe("multiselection menu", function () {
            beforeEach(function () {
                this.page.$('.select_all').prop('checked', true).trigger('change');
                spyOn(this.jobs[0], 'disable');
                spyOn(this.jobs[0], 'enable');
                spyOn(this.jobs[0], 'destroy');
            });

            describe("clicking the 'disable' action", function () {
                it("disables all selected jobs", function () {
                    this.page.multiSelectSidebarMenu.$('.disable_jobs').click();
                    expect(this.jobs[0].disable).toHaveBeenCalled();
                });
            });

            describe("clicking then 'enable' action", function () {
                it("enables all selected jobs", function () {
                    this.page.multiSelectSidebarMenu.$('.enable_jobs').click();
                    expect(this.jobs[0].enable).toHaveBeenCalled();
                });
            });

            describe("clicking the 'delete' action", function () {
                beforeEach(function () {
                    this.modalSpy = stubModals();
                });

                itBehavesLike.aDialogLauncher("a.delete_jobs", chorus.alerts.MultipleJobDelete);
            });
        });
    });

    describe("when the collection is loaded", function () {
        beforeEach(function () {
            var jobs = [backboneFixtures.job()];
            spyOn(this.page.collection, 'fetch');
            this.server.completeFetchFor(this.page.collection, jobs);
            this.server.completeFetchFor(this.workspace);
        });

        describe("polling the collection", function () {
            it("waits for an interval", function () {
                expect(this.page.collection.fetch).not.toHaveBeenCalled();
                this.clock.tick(30001);
                expect(this.page.collection.fetch).toHaveBeenCalled();
            });

            it("ceases with teardown", function () {
                this.page.teardown();
                this.page.collection.fetch.reset();
                this.clock.tick(300001);
                expect(this.page.collection.fetch).not.toHaveBeenCalled();
            });
        });
    });
});