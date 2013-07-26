describe("chorus.views.JobContentDetails", function () {

    beforeEach(function () {
        this.job = backboneFixtures.job();
        this.view = new chorus.views.JobContentDetails({model: this.job});
        this.modalSpy = stubModals();
        this.view.render();
    });

    describe("clicking the 'Add Task' button", function () {
        itBehavesLike.aDialogLauncher('button.create_task', chorus.dialogs.CreateJobTask);
    });

    describe("clicking the 'Enable' button", function () {
        it("posts to the API with the right parameters", function () {
            this.view.$('button.toggle_enabled').click();

            var params = this.server.lastUpdate().params();
            expect(params['job[enabled]']).toBe("true");
        });

        it("shows the enabling/disabling text", function () {
            this.view.$('button.toggle_enabled').click();
            expect(this.view.$('button.toggle_enabled')).toContainTranslation("job.actions.saving");
            expect(this.view.$('button.toggle_enabled')).toBeDisabled();
        });

        context("when the save Succeeds", function () {
            it("toggles the button text", function () {
                expect(this.view.$('button.toggle_enabled')).toContainTranslation('job.actions.enable');
                this.view.$('button.toggle_enabled').click();
                this.server.completeUpdateFor(this.view.model);
                expect(this.view.$('button.toggle_enabled')).toContainTranslation('job.actions.disable');
            });

            it("toggles the action bar styling", function () {
                expect(this.view.$('.action_bar')).toHaveClass('action_bar_limited');
                this.view.$('button.toggle_enabled').click();
                this.server.completeUpdateFor(this.view.model);
                expect(this.view.$('.action_bar')).toHaveClass('action_bar_highlighted');
            });

        });
    });

    itBehavesLike.aDialogLauncher('edit_schedule', chorus.dialog.EditJob);
});