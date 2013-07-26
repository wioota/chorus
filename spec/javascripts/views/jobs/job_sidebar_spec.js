describe("chorus.views.JobSidebar", function () {
    beforeEach(function () {
        this.job = backboneFixtures.jobSet().at(0);
        this.view = new chorus.views.JobSidebar({model: this.job});
        this.view.render();
    });

    it("displays the job name", function () {
        expect(this.view.$(".name")).toContainText(this.job.get("name"));
    });

    context("when the job is enabled", function () {
        beforeEach(function () {
            this.job.set("state", "scheduled");
        });

        it("shows a disable link", function () {
            expect(this.view.$('.disable')).toExist();
            expect(this.view.$('.enable')).not.toExist();
        });

        context("when disable is clicked", function() {
            beforeEach(function() {
                spyOn(this.job, "save");
            });
            it("makes a request to disable the job", function() {
                this.view.$('.disable').click();
                expect(this.job.save).toHaveBeenCalledWith({ enabled: false }, { wait: true });
            });

        });
    });

    context("when the job is disabled", function () {
        beforeEach(function () {
            this.job.set('state', 'disabled');
        });

        it("shows an enable link", function () {
            expect(this.view.$('.enable')).toExist();
            expect(this.view.$('.disable')).not.toExist();
        });

        context("when enable is clicked", function() {
            beforeEach(function() {
                spyOn(this.job, "save");
            });
            it("makes a request to enable the job", function() {
                this.view.$('.enable').click();
                expect(this.job.save).toHaveBeenCalledWith({ enabled: true }, { wait: true });
            });

        });
    });

    describe("clicking EditJob", function () {
        beforeEach(function () {
            this.modalSpy = stubModals();
        });
        itBehavesLike.aDialogLauncher("a.edit_job", chorus.dialogs.EditJob);
    });
});