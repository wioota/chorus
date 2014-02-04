describe("chorus.presenters.Base", function() {
    beforeEach(function() {
        this.model = new chorus.models.Base();
        this.options = { anOption: true };
        this.presenter = new chorus.presenters.Base(this.model, this.options);
    });

    it("stores the given model and options hash", function() {
        expect(this.presenter.model).toBe(this.model);
        expect(this.presenter.options).toBe(this.options);
    });

    describe("#workFlowsEnabled", function() {
        context("when work flows are enabled", function() {
            beforeEach(function() {
                chorus.models.Config.instance().set("workflowEnabled", true);
            });

            it("returns true", function() {
                expect(this.presenter.workFlowsEnabled()).toBeTruthy();
            });
        });

        context("when work flows are not enabled", function() {
            beforeEach(function() {
                chorus.models.Config.instance().set("workflowEnabled", false);
            });

            it("returns false", function() {
                expect(this.presenter.workFlowsEnabled()).toBeFalsy();
            });
        });
    });
});
