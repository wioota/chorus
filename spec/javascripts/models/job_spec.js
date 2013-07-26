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

    describe("disable", function () {
        beforeEach(function () {
            spyOn(this.model, "save");
        });
        it("makes a request to disable the job", function () {
            this.model.disable();
            expect(this.model.save).toHaveBeenCalledWith({ enabled: false }, { wait: true });
        });
    });

    describe("enable", function () {
        beforeEach(function () {
            spyOn(this.model, "save");
        });
        it("makes a request to enable the job", function () {
            this.model.enable();
            expect(this.model.save).toHaveBeenCalledWith({ enabled: true }, { wait: true });
        });
    });
});