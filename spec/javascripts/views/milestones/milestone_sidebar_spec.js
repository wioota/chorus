describe("chorus.views.MilestoneSidebar", function () {
    beforeEach(function () {
        this.milestone = backboneFixtures.milestoneSet().first();
        this.view = new chorus.views.MilestoneSidebar({model: this.milestone});
        this.modalSpy = stubModals();
        this.view.render();
    });

    it("displays the milestone name", function () {
        expect(this.view.$(".name")).toContainText(this.milestone.get("name"));
    });

    describe("clicking 'Delete Milestone'", function () {
        itBehavesLike.aDialogLauncher("a.delete_milestone", chorus.alerts.MilestoneDelete);
    });
});