describe("chorus.views.JobIndexPageButtons", function () {
    beforeEach(function () {
        this.workspace = backboneFixtures.workspace();
        this.workspace.loaded = false;
        this.view = new chorus.views.JobIndexPageButtons({model: this.workspace});
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
        context("and the user can update the workspace", function() {
            beforeEach(function() {
                this.modalSpy = stubModals();
                spyOn(this.workspace, 'canUpdate').andReturn(true);
                this.server.completeFetchFor(this.workspace);
            });

            it("renders buttons", function() {
                expect(this.view.$("button.create_job")).toExist();
                expect(this.view.$("button.create_job")).toContainTranslation("actions.create_job");
            });
        });
    });
});