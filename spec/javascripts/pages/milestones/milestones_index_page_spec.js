describe("chorus.pages.MilestonesIndexPage", function () {
    beforeEach(function () {
        this.workspace = backboneFixtures.workspace();
        this.page = new chorus.pages.MilestonesIndexPage(this.workspace.id);
    });

    describe("breadcrumbs", function() {
        beforeEach(function() {
            this.workspace.set({name: "Cool Workspace"});
            this.server.completeFetchFor(this.workspace);
            this.page.render();
        });

        it("renders home > Workspaces > {workspace name} > Milestones", function() {
            expect(this.page.$(".breadcrumb:eq(0) a").attr("href")).toBe("#/");
            expect(this.page.$(".breadcrumb:eq(0) a").text()).toMatchTranslation("breadcrumbs.home");

            expect(this.page.$(".breadcrumb:eq(1) a").attr("href")).toBe("#/workspaces");
            expect(this.page.$(".breadcrumb:eq(1) a").text()).toMatchTranslation("breadcrumbs.workspaces");

            expect(this.page.$(".breadcrumb:eq(2) a").attr("href")).toBe("#/workspaces/" + this.workspace.id);
            expect(this.page.$(".breadcrumb:eq(2) a").text()).toBe("Cool Workspace");

            expect(this.page.$(".breadcrumb:eq(3)").text().trim()).toMatchTranslation("breadcrumbs.milestones");
        });
    });

    describe("subnav", function () {
        it("should create the subnav on the milestones tab", function () {
            expect(this.page.subNav).toBeA(chorus.views.SubNav);
        });
    });

    describe("#setup", function () {
        it("fetches the collection", function() {
            expect(this.page.collection).toHaveBeenFetched();
        });
    });

    describe("#render", function () {
        beforeEach(function () {
            this.page.render();
        });

        describe("when the collection is loaded", function () {
            beforeEach(function () {
                this.milestones = backboneFixtures.milestoneSet();
                spyOn(this.page.collection, 'fetch');
                this.server.completeFetchFor(this.page.collection, this.milestones.models);
                this.server.completeFetchFor(this.workspace);
            });

            it("renders each milestone", function () {
                this.milestones.each(function (milestone) {
                    expect(this.page.$el).toContainText(milestone.get('name'));
                }, this);
            });

            it("renders a sidebar with the selected milestone name", function () {
                expect(this.page.$('#sidebar')).toContainText(this.milestones.at(0).get('name'));
            });

            describe("when invalidated is triggered on the model", function () {
                it("refetches the model", function () {
                    this.page.collection.trigger('invalidated');
                    expect(this.page.collection.fetch).toHaveBeenCalled();
                });
            });

            describe("actions", function () {
                beforeEach(function () {
                    this.modalSpy = stubModals();
                });

                itBehavesLike.aDialogLauncher('button.create_milestone', chorus.dialogs.ConfigureMilestone);
            });
        });

        describe("when fetching the collection is forbidden", function () {
            beforeEach(function () {
                spyOn(Backbone.history, "loadUrl");
                this.server.lastFetchFor(this.page.collection).failForbidden({license: "NOT_LICENSED"});
            });

            it("routes to the not licensed page", function() {
                expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/notLicensed");
            });
        });
    });
});
