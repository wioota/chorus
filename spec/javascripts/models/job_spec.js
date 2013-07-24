describe("chorus.models.Job", function () {
    beforeEach(function () {
        this.model = backboneFixtures.job();
    });

    describe("runsOnDemand", function () {
        context("when the model's interval unit is 'on demand'", function () {
            beforeEach(function () {
                this.model.set('intervalUnit', 'on_demand');
            });
            it("return true", function () {
                expect(this.model.runsOnDemand()).toBeTruthy();
            });
        });
        context("when the model's interval unit is a unit of time", function () {
            beforeEach(function () {
                this.model.set('intervalUnit', 'hours');
            });
            it("return true", function () {
                expect(this.model.runsOnDemand()).toBeFalsy();
            });
        });
    });
});