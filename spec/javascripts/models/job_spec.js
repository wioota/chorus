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

    describe("#toggleEnabled", function () {
        beforeEach(function () {
            spyOn(this.model, 'enable');
            spyOn(this.model, 'disable');
        });

        context("when enabled", function () {
            beforeEach(function () {
                this.model.set("enabled", true);
                this.model.toggleEnabled();
            });

            it("disables", function () {
                expect(this.model.disable).toHaveBeenCalled();
            });
        });

        context("when disabled", function () {
            beforeEach(function () {
                this.model.set("enabled", false);
                this.model.toggleEnabled();
            });

            it("enables", function () {
                expect(this.model.enable).toHaveBeenCalled();
            });
        });
    });

    describe("tasks", function () {
        it("are not memoized", function () {
            expect(this.model.tasks().models.length).toBeGreaterThan(0);
            this.model.fetch();
            this.server.completeFetchFor(this.model, {tasks: []});
            expect(this.model.tasks().models).toEqual([]);
        });
    });

    describe("nextRunDate", function () {
        beforeEach(function () {
            this.model = new chorus.models.Job();
        });

        it("defaults to an hour from creation", function () {
            expect(this.model.nextRunDate().format()).toEqual(moment().add(1, 'hour').format());
        });
    });

    describe("run", function () {
        beforeEach(function () {
            spyOn(chorus, 'toast');
            this.model.run();
        });

        it("saves", function () {
            var postUrl = this.server.lastUpdateFor(this.model).url;
            expect(postUrl).toContain("/workspaces/" + this.model.workspace().id + "/jobs/" + this.model.id);
        });


        it("passes the 'job_action: run' parameter", function () {
            var params = this.server.lastUpdateFor(this.model).params();
            expect(params['job[job_action]']).toEqual('run');
        });

        it("does not toast without success", function () {
            expect(chorus.toast).not.toHaveBeenCalled();
        });


        context("when the save succeeds", function () {
            beforeEach(function () {
                this.server.lastUpdate().succeed();
            });

            it("flashes a toast message", function () {
                expect(chorus.toast).toHaveBeenCalledWith('job.running_toast', {jobName: this.model.name()});
            });
        });
    });

    describe("stop", function () {
        beforeEach(function () {
            spyOn(chorus, 'toast');
            this.model.stop();
        });

        it("saves", function () {
            var postUrl = this.server.lastUpdateFor(this.model).url;
            expect(postUrl).toContain("/workspaces/" + this.model.workspace().id + "/jobs/" + this.model.id);
        });

        it("sets the jobs status to 'stopping'", function () {
            expect(this.model.get('status')).toBe('stopping');
        });

        it("passes the 'job_action: kill' parameter", function () {
            var params = this.server.lastUpdateFor(this.model).params();
            expect(params['job[job_action]']).toEqual('kill');
        });

        it("does not toast without success", function () {
            expect(chorus.toast).not.toHaveBeenCalled();
        });

        context("when the save succeeds", function () {
            beforeEach(function () {
                this.server.lastUpdate().succeed();
            });

            it("flashes a toast message", function () {
                expect(chorus.toast).toHaveBeenCalledWith('job.stopping_toast', {jobName: this.model.name()});
            });
        });
    });
});