describe("chorus.dialogs.EditJob", function () {
    beforeEach(function () {
        stubDefer();
        this.jobPlan = {
            name: 'Apples',
            interval_value: '2',
            interval_unit: 'weeks',
            month: "7",
            day: "9",
            year: "3013",
            hour: '1',
            minute: '5',
            meridiem: 'am'
        };
        this.job = backboneFixtures.job();
        this.workspace = this.job.get("workspace");

        spyOn(chorus.router, "navigate");

        this.dialog = new chorus.dialogs.EditJob({model: this.job, workspace: this.workspace});
        spyOn(this.dialog.endDatePicker, "enable");
        this.dialog.render();
    });

    it("has all the dialog pieces", function () {
        expect(this.dialog.title).toMatchTranslation("job.dialog.edit.title");
        expect(this.dialog.$('button.submit').text()).toMatchTranslation("job.dialog.edit.submit");
        expect(this.dialog.$('button.cancel').text()).toMatchTranslation("actions.cancel");
    });

    describe("prepopulating the dialog with the job's attributes", function () {
        it("populates name", function () {
            expect(this.dialog.$("input.name").val()).toBe(this.job.get("name"));
        });

        it("populates intervalValue and itnervalUnit", function () {
            expect(this.dialog.$("input.interval_value").val()).toBe(this.job.get("intervalValue").toString());
            expect(this.dialog.$("select.interval_unit").val()).toBe(this.job.get("intervalUnit"));
        });

        it("populates next run date", function () {
            var nextRunDate = this.job.nextRunDate().startOf("minute");
            nextRunDate.minute(Math.floor(nextRunDate.minute() / 5) * 5);

            expect(this.dialog.buildStartDate().toDate()).toEqual(nextRunDate.toDate());
        });

        it("populates end date", function () {
            var endRunDate = this.job.endRunDate().startOf("day");

            expect(this.dialog.buildEndDate().toDate()).toEqual(endRunDate.toDate());
        });
    });

    context("editing a Job that runs on schedule with an end run time", function () {
        describe("selecting 'on schedule'", function () {

            it("should show schedule options", function () {
                expect(this.dialog.$('.interval_options')).not.toHaveClass('hidden');
            });

            it("should have a select with hours, days, weeks, months as options", function () {
                expect(this.dialog.$(".interval_unit option[value=hours]")).toContainTranslation("job.interval_unit.hours");
                expect(this.dialog.$(".interval_unit option[value=days]")).toContainTranslation("job.interval_unit.days");
                expect(this.dialog.$(".interval_unit option[value=weeks]")).toContainTranslation("job.interval_unit.weeks");
                expect(this.dialog.$(".interval_unit option[value=months]")).toContainTranslation("job.interval_unit.months");
            });

            it("should show the start date controls", function () {
                expect(this.dialog.$(".start_date_widget")).toExist();
            });

            it("should show the end date controls", function () {
                expect(this.dialog.$(".end_date_widget")).toExist();
            });
        });

        context("with valid field values", function () {
            beforeEach(function () {
                this.dialog.$('input:radio#onSchedule').prop("checked", true).trigger("change");
                this.dialog.$('input:radio#onDemand').prop("checked", false).trigger("change");
                var dialog = this.dialog;
                var jobPlan = this.jobPlan;
                _.each(_.keys(this.jobPlan), function (prop) {
                    var selects = ['interval_unit', 'meridiem', 'hour', 'minute'];
                    var element = (_.contains(selects, prop) ? 'select.' : 'input.');
                    dialog.$(element + prop).val(jobPlan[prop]).trigger("change").trigger("keyup");
                });
            });

            it("should enable the submit button", function () {
                expect(this.dialog.$('button.submit')).toBeEnabled();
            });

            it("should enable the end date widget", function () {
                expect(this.dialog.endDatePicker.enable).toHaveBeenCalled();
            });

            describe("submitting the form", function () {
                beforeEach(function () {
                    this.dialog.$("form").submit();
                });

                it("posts the form elements to the API", function () {
                    var postUrl = this.server.lastUpdateFor(this.dialog.model).url;
                    expect(postUrl).toContain("/workspaces/" + this.workspace.id + "/jobs/" + this.job.id);
                });

                it("posts with the correct values", function () {
                    var params = this.server.lastUpdate().params();
                    var date = moment(new Date(this.jobPlan.year, parseInt(this.jobPlan.month, 10) - 1, this.jobPlan.day, this.jobPlan.hour, this.jobPlan.minute));
                    var endDate = moment(new Date(this.jobPlan.year, parseInt(this.jobPlan.month, 10) - 1, this.jobPlan.day));
                    expect(params['job[name]']).toEqual(this.jobPlan.name);
                    expect(params['job[interval_unit]']).toEqual(this.jobPlan.interval_unit);
                    expect(params['job[interval_value]']).toEqual(this.jobPlan.interval_value);
                    expect(params['job[next_run]']).toEqual(date.toISOString());
                    expect(params['job[end_run]']).toEqual(endDate.toISOString());
                });

                context("when the save succeeds", function () {
                    beforeEach(function () {
                        spyOn(this.dialog, "closeModal");
                        spyOn(chorus, "toast");
                        this.server.lastUpdate().succeed();
                    });

                    it("it should close the modal", function () {
                        expect(this.dialog.closeModal).toHaveBeenCalled();
                    });

                    it("should create a toast", function () {
                        expect(chorus.toast).toHaveBeenCalledWith(this.dialog.message);
                    });
                });
            });
        });

        context("with invalid field values", function () {
            beforeEach(function () {
                this.dialog.$('input.interval_value').val('').trigger("keyup");
            });

            it("leaves the form disabled", function () {
                expect(this.dialog.$('button.submit')).toBeDisabled();
            });
        });

        context("when switching it to onDemand", function () {
            beforeEach(function () {
                this.dialog.$('input:radio#onSchedule').prop("checked", false).trigger("change");
                this.dialog.$('input:radio#onDemand').prop("checked", true).trigger("change");
            });

            it("should enable the submit button", function () {
                expect(this.dialog.$('button.submit')).toBeEnabled();
            });

            it("should hide the interval options", function () {
                expect(this.dialog.$(".interval_options")).toHaveClass("hidden");
            });

            describe("submitting the form", function () {
                beforeEach(function () {
                    this.dialog.$("form").submit();
                });

                it("posts the form elements to the API", function () {
                    var postUrl = this.server.lastUpdateFor(this.dialog.model).url;
                    expect(postUrl).toContain("/workspaces/" + this.workspace.id + "/jobs/" + this.job.id);
                });

                it("posts with the correct values", function () {
                    var params = this.server.lastUpdate().params();
                    expect(params['job[name]']).toEqual(this.job.get("name"));
                    expect(params['job[interval_unit]']).toEqual("on_demand");
                    expect(params['job[interval_value]']).toEqual("0");
                    expect(params['job[next_run]']).toBe("invalid");
                    expect(params['job[end_run]']).toBe("invalid");
                });

                context("when the save succeeds", function () {
                    beforeEach(function () {
                        spyOn(this.dialog, "closeModal");
                        spyOn(chorus, "toast");
                        this.server.lastUpdate().succeed();
                    });

                    it("it should close the modal", function () {
                        expect(this.dialog.closeModal).toHaveBeenCalled();
                    });

                    it("should create a toast", function () {
                        expect(chorus.toast).toHaveBeenCalledWith(this.dialog.message);
                    });
                });
            });
        });
    });
});