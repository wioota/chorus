describe("chorus.dialogs.CreateJob", function () {
    beforeEach(function () {
        this.plannedJob = {name: 'Apples', intervalValue: '2', intervalUnit: 'weeks'};

        this.workspace = backboneFixtures.workspace();
        this.dialog = new chorus.dialogs.CreateJob({workspace: this.workspace});
        this.dialog.render();
    });

    it("has all the dialog pieces", function () {
        expect(this.dialog.title).toMatchTranslation("create_job_dialog.title");
        expect(this.dialog.$('button.submit').text()).toMatchTranslation("create_job_dialog.submit");
        expect(this.dialog.$('button.cancel').text()).toMatchTranslation("actions.cancel");
    });

    context("creating a Job that runs On Demand", function () {
        beforeEach(function () {
            this.plannedJob.intervalUnit = 'on_demand';
        });


        it("leaves interval fields disabled", function () {
            expect(this.dialog.$('select.interval_unit')).toBeDisabled();
            expect(this.dialog.$('input.interval_value')).toBeDisabled();
        });

        context("with valid field values", function () {
            beforeEach(function () {
                this.dialog.$('input.name').val(this.plannedJob.name).trigger("keyup");
            });

            it("should enable the submit button", function () {
                expect(this.dialog.$('button.submit')).toBeEnabled();
            });

            describe("submitting the form", function () {
                beforeEach(function () {
                    this.dialog.$("form").submit();
                });

                it("posts the form elements to the API", function () {
                    var postUrl = this.server.lastCreateFor(this.dialog.model).url;
                    expect(postUrl).toContain("/workspaces/" + this.workspace.id + "/jobs");
                });

                it("posts with the correct values", function() {
                    var params = this.server.lastCreate().params();
                    expect(params['job[name]']).toEqual(this.plannedJob.name);
                    expect(params['job[interval_unit]']).toEqual(this.plannedJob.intervalUnit);
                    expect(params['job[interval_value]']).toEqual("0");
                });

                context("when the save fails", function () {
                    beforeEach(function () {
                        this.server.lastCreate().failUnprocessableEntity({
                            fields: {
                                BASE: { SOME_FAKE_ERROR: {}}
                            }
                        });
                    });

                    it("should display the errors for the model", function() {
                        expect(this.dialog.$(".errors li")).toExist();
                    });
                });

                context("when the save succeeds", function () {
                    beforeEach(function () {
                        spyOn(this.dialog, "closeModal");
                        spyOn(chorus, "toast");
                        this.server.lastCreate().succeed();
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
            it("leaves the form disabled", function () {
                expect(this.dialog.$('button.submit')).toBeDisabled();
            });
        });
    });

    context("creating a Job that runs on schedule", function () {
        describe("selecting 'on schedule'", function () {
            beforeEach(function () {
                this.dialog.$('input:radio#onSchedule').prop("checked", true).trigger('change');
            });

            it("enables the interval fields", function () {
                expect(this.dialog.$('select.interval_unit')).toBeEnabled();
                expect(this.dialog.$('input.interval_value')).toBeEnabled();
            });

            it("should have a select with hourly, daily, weekly, monthly as options", function() {
                expect(this.dialog.$(".interval_unit option[value=hours]")).toContainTranslation("job.interval_unit.hours");
                expect(this.dialog.$(".interval_unit option[value=days]")).toContainTranslation("job.interval_unit.days");
                expect(this.dialog.$(".interval_unit option[value=weeks]")).toContainTranslation("job.interval_unit.weeks");
                expect(this.dialog.$(".interval_unit option[value=months]")).toContainTranslation("job.interval_unit.months");

                expect(this.dialog.$(".interval_unit").val()).toBe("hours");
            });
        });

        context("with valid field values", function () {
            beforeEach(function () {
                this.dialog.$('input.name').val(this.plannedJob.name).trigger("keyup");
                this.dialog.$('input:radio#onSchedule').prop("checked", true).trigger("change");

                this.dialog.$('input.interval_value').val(this.plannedJob.intervalValue).trigger("keyup");
                this.dialog.$('select.interval_unit').val(this.plannedJob.intervalUnit).trigger("change");
            });

            it("should enable the submit button", function () {
                expect(this.dialog.$('button.submit')).toBeEnabled();
            });

            describe("submitting the form", function () {
                beforeEach(function () {
                    this.dialog.$("form").submit();
                });

                it("posts the form elements to the API", function () {
                    var postUrl = this.server.lastCreateFor(this.dialog.model).url;
                    expect(postUrl).toContain("/workspaces/" + this.workspace.id + "/jobs");
                });

                it("posts with the correct values", function() {
                    var params = this.server.lastCreate().params();
                    expect(params['job[name]']).toEqual(this.plannedJob.name);
                    expect(params['job[interval_unit]']).toEqual(this.plannedJob.intervalUnit);
                    expect(params['job[interval_value]']).toEqual(this.plannedJob.intervalValue);
                });
            });
        });

        context("with invalid field values", function () {
            it("leaves the form disabled", function () {
                expect(this.dialog.$('button.submit')).toBeDisabled();
            });
        });
    });

});