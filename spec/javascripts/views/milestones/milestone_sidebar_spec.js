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

    describe('milestone state toggle', function () {
        context('the milestone is "planned"', function () {
            beforeEach(function () {
                this.milestone.set('state', 'planned');
                this.view.render();
            });

            it("displays a 'complete' link", function () {
                expect(this.view.$('.toggle_state')).toContainTranslation('milestone.actions.toggle.planned');
            });

            describe("clicking the link", function () {
                beforeEach(function () {
                    spyOn(this.milestone, "toggleState");
                    this.view.$('.toggle_state').click();
                });

                it("toggles the state", function () {
                    expect(this.milestone.toggleState).toHaveBeenCalled();
                });
            });
        });

        context('the milestone is "achieved"', function () {
            beforeEach(function () {
                this.milestone.set('state', 'achieved');
                this.view.render();
            });

            it("displays a 'restart' link", function () {
                expect(this.view.$('.toggle_state')).toContainTranslation('milestone.actions.toggle.achieved');
            });
        });
    });
});