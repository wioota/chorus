describe("chorus.views.JobsIndexPageButtons", function () {
    beforeEach(function () {
        this.modalSpy = stubModals();
        this.workspace = backboneFixtures.workspace();
        this.workspace.loaded = false;
        this.view = new chorus.views.JobsIndexPageButtons({model: this.workspace});
    });

    context("before the workspace is fetched", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("does not render any buttons", function() {
            expect(this.view.$("button").length).toBe(0);
        });
    });

    context("after the workspace is fetched", function() {
        beforeEach(function () {
            this.server.completeFetchFor(this.workspace);
        });

        context("and the user can update the workspace", function() {
            beforeEach(function() {
                spyOn(this.workspace, 'canUpdate').andReturn(true);
            });

            it("renders buttons", function() {
                expect(this.view.$("button.create_job")).toExist();
                expect(this.view.$("button.create_job")).toContainTranslation("actions.create_job");
            });

            describe("the 'Create' button", function () {
                itBehavesLike.aDialogLauncher('button.create_job', chorus.dialogs.ConfigureJob);
            });
        });
    });

});