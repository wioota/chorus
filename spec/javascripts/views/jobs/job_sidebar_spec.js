describe("chorus.views.JobSidebar", function () {
    beforeEach(function () {
        this.job = backboneFixtures.jobSet().at(0);
        this.view = new chorus.views.JobSidebar({model: this.job});
        this.view.render();
    });

    it("displays the job name", function() {
        expect(this.view.$(".name")).toContainText(this.job.get("name"));
    });

    context("when the job is enabled", function () {
        beforeEach(function () {
            expect(this.job.get('state')).not.toEqual("disabled");
        });

        it("shows a disable link", function () {
            expect(this.view.$('.disable')).toExist();
            expect(this.view.$('.enable')).not.toExist();
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
    });
});