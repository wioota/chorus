describe("chorus.views.JobItem", function () {
    beforeEach(function() {
        var jobSet = backboneFixtures.jobSet();
        this.model = jobSet.at(0);
        this.model.set('lastRun', '2011-11-08T18:06:51Z');
        this.model.set('nextRun', '2050-11-08T18:06:51Z');
        this.view = new chorus.views.JobItem({ model: this.model });
        this.view.render();
    });

    it("links the job's name to its show page", function() {
        expect(this.view.$("a.name")).toHaveText(this.model.get("name"));
        expect(this.view.$("a.name")).toHaveHref(this.model.showUrl());
    });

    it("includes the correct job icon (non-image)", function() {
        expect(this.view.$("img")).toHaveAttr("src", "/images/jobs/job.png");
    });

    describe("frequency", function () {
        context("when the Job is run on Demand", function () {
            beforeEach(function () {
                this.model.set('intervalUnit', 'on_demand');
            });

            it("displays the 'on demand' text", function () {
                expect(this.view.$(".frequency")).toContainTranslation("job.frequency.on_demand");
            });
        });

        context("when the Job is run on a schedule", function () {
            var three, days;

            beforeEach(function () {
                three = 3; days = 'days';
                this.model.set('intervalValue', three);
                this.model.set('intervalUnit', days);
            });

            it("displays the schedule text", function () {
                var $frequency = this.view.$(".frequency");
                expect($frequency).toContainTranslation("job.frequency.on_schedule", {intervalValue: three, intervalUnit: days});
            });
        });
    });

    it("includes the job's state", function () {
        expect(this.view.$(".state")).toContainTranslation("job.state." + this.model.get("state"));
    });

    context("when last_run is populated", function () {
        it("includes when the job was last run", function () {
            expect(this.view.$(".last_run")).toContainText('2011');
        });
    });

    context("when last_run is empty", function () {
        beforeEach(function () {
            this.model.set('lastRun', null);
            this.view.render();
        });

        it("shows a dash", function () {
            expect(this.view.$(".last_run")).toContainText('-');
        });
    });

    context("when next_run is populated", function () {
        it("includes when the job will be run next", function () {
            expect(this.view.$(".next_run")).toContainText('2050');
        });
    });

    context("when last_run is empty", function () {
        beforeEach(function () {
            this.model.set('nextRun', null);
            this.view.render();
        });

        it("shows a dash", function () {
            expect(this.view.$(".next_run")).not.toExist();
        });
    });

    describe("when the model received an 'invalidated' trigger", function() {
        beforeEach(function() {
            spyOn(this.model, "fetch");
        });

        it("reloads the model", function() {
            this.model.trigger("invalidated");
            expect(this.model.fetch).toHaveBeenCalled();
        });
    });
});