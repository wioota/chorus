describe("chorus.models.License", function () {
    beforeEach(function () {
        this.model = backboneFixtures.license();
    });

    describe("#homePage", function() {
        context("when there is a homePage attr", function() {
            beforeEach(function () {
                this.model.set("homePage", "WorkspaceIndex");
            });

            it("it returns that value", function() {
                expect(this.model.homePage()).toBe("WorkspaceIndex");
            });
        });

        context("when there is not a homePage attr", function() {
            beforeEach(function () {
                this.model.set("homePage", null);
            });

            it("it returns Dashboard", function() {
                expect(this.model.homePage()).toBe("Dashboard");
            });
        });
    });
});
