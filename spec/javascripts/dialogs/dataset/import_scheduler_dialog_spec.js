describe("chorus.dialogs.ImportScheduler", function() {
    beforeEach(function() {
        this.dataset = rspecFixtures.workspaceDataset.datasetTable();
        this.importSchedules = rspecFixtures.datasetImportScheduleSet();
        _.extend(this.importSchedules.attributes, {
            datasetId: this.dataset.get('id'),
            workspaceId: this.dataset.get("workspace").id
        });
        this.importSchedule = this.importSchedules.at(0);
        this.importSchedule.set({
            datasetId: this.dataset.get('id'),
            workspaceId: this.dataset.get('workspace').id
        });
        this.workspace = rspecFixtures.workspace(this.dataset.get('workspace'));
        this.importSchedule.unset('sampleCount');
        this.importSchedule.unset('id');
    });

    describe("creating a new schedule", function() {
        beforeEach(function() {
            this.dialog = new chorus.dialogs.ImportScheduler({
                dataset: this.dataset,
                workspace: this.workspace,
                action: "create_schedule"
            });
            this.server.completeFetchFor(this.importSchedules, []);
            spyOn(chorus.views.ImportSchedule.prototype, "enable");
            this.dialog.render();
            this.dialog.$(".new_table input.name").val("abc").trigger("keyup");
        });

        it("takes the workspace from the options passed", function() {
            expect(this.dialog.workspace).toBe(this.workspace);
        });

        it("should have a truncate checkbox", function() {
            expect(this.dialog.$(".truncate")).toExist();
        });

        it("should set executeAfterSave to be false on the DatasetImport", function() {
            expect(this.dialog.model.executeAfterSave).toBeFalsy();
        });

        it("should have the correct title", function() {
            expect(this.dialog.title).toMatchTranslation("import.title_schedule");
        });

        it("should have the right submit button text", function() {
            expect(this.dialog.submitText).toMatchTranslation("import.begin_schedule");
        });

        it("should show the schedule controls", function() {
            expect(this.dialog.$(".schedule_widget")).toExist();
        });

        it("sets the time fields to the model defaults", function() {
            expect(this.dialog.$('select.hours')).toHaveValue(this.dialog.model.startTime().toString("h"));
        });

        function itShouldHaveAllTheFields(selector) {
            it("should enable the schedule view", function() {
                expect(chorus.views.ImportSchedule.prototype.enable).toHaveBeenCalled();
            });

            context("when all the fields are filled out and the form is submitted", function() {
                beforeEach(function() {
                    this.dialog.$("input:checked[name='truncate']").prop("checked", false).change();

                    this.dialog.$("select[name='toTable']").eq(0).attr("selected", true);
                    this.dialog.$(".existing_table a.dataset_picked").text("a");

                    this.dialog.$("input[name='limit_num_rows']").prop("checked", true).change();
                    this.dialog.$("input[name='sampleCount']").val(123);

                    this.dialog.$(".start input[name='year']").val("2012");
                    this.dialog.$(".start input[name='month']").val("02");
                    this.dialog.$(".start input[name='day']").val("29");

                    this.dialog.$(".end input[name='year']").val("2012");
                    this.dialog.$(".end input[name='month']").val("03");
                    this.dialog.$(".end input[name='day']").val("21");

                    this.dialog.$("select.ampm").val("PM");
                    this.dialog.$("select.hours").val("12");
                    this.dialog.$("select.minutes").val("09");
                    this.startDatetime = new Date(2012, 1, 29, 12, 9, 0, 0);
                    expect(this.dialog.$("button.submit")).toBeEnabled();

                });

                it("should put the values in the correct API form fields", function() {
                    this.dialog.$("button.submit").click();

                    var params = this.server.lastCreate().params();
                    expect(params["dataset_import_schedule[truncate]"]).toBe("false");
                    expect(params["dataset_import_schedule[sample_count]"]).toBe("123");
                    expect(params["dataset_import_schedule[start_datetime]"]).toBe(this.startDatetime.toISOString());
                    expect(params["dataset_import_schedule[end_date]"]).toBe("2012-03-21");
                });

                context("when the date is invalid", function() {
                    beforeEach(function() {
                        this.dialog.$(".start input[name='day']").val("32");
                    });

                    it("displays an 'invalid date' message", function() {
                        this.dialog.$("button.submit").click();
                        expect(this.dialog.$(".errors")).toContainText("32 is not a valid value for days.");
                        expect(this.dialog.$('button.submit').isLoading()).toBeFalsy();
                    });
                });
            });

            context("when the row limit is not checked and the form is submitted", function() {
                beforeEach(function() {
                    this.dialog.$("input:checked[name='truncate']").prop("checked", false).change();

                    this.dialog.$("select[name='toTable']").eq(0).attr("selected", true);

                    this.dialog.$(".existing_table a.dataset_picked").text("a");

                    this.dialog.$("input[name='limit_num_rows']").prop("checked", false);

                    this.dialog.$(".start input[name='year']").val("2012");
                    this.dialog.$(".start input[name='month']").val("02");
                    this.dialog.$(".start input[name='day']").val("29");

                    this.dialog.$(".end input[name='year']").val("2012");
                    this.dialog.$(".end input[name='month']").val("03");
                    this.dialog.$(".end input[name='day']").val("21");

                    this.dialog.$("select.ampm").val("PM");
                    this.dialog.$("select.hours").val("12");
                    this.dialog.$("select.minutes").val("09");

                    this.dialog.onInputFieldChanged();
                    expect(this.dialog.$("button.submit")).toBeEnabled();

                    this.dialog.$("button.submit").click();

                    this.startDatetime = new Date(2012, 1, 29, 12, 9, 0, 0);
                });

                it("should put the values in the correct API form fields", function() {
                    var params = this.server.lastCreate().params();
                    expect(params["dataset_import_schedule[truncate]"]).toBe("false");
                    expect(params["dataset_import_schedule[sample_count]"]).toBe("");
                    expect(params["dataset_import_schedule[start_datetime]"]).toBe(this.startDatetime.toISOString());
                    expect(params["dataset_import_schedule[end_date]"]).toBe("2012-03-21");
                });

            });
        }

        context("when 'Import into New Table' is checked", function() {
            beforeEach(function() {
                this.dialog.$(".new_table input:radio").prop("checked", true).change();
            });

            itShouldHaveAllTheFields(".new_table");

            it("disables the 'Select a table' link", function() {
                expect(this.dialog.$("a.dataset_picked")).toHaveClass("hidden");
                expect(this.dialog.$("span.dataset_picked")).not.toHaveClass("hidden");
            });
        });

        context("when 'Import into Existing Table' is checked", function() {
            beforeEach(function() {
                this.dialog.$(".new_table input:radio").prop("checked", false);
                this.dialog.$(".existing_table input:radio").prop("checked", true).change();
            });

            itShouldHaveAllTheFields(".existing_table");
        });

        context("when the dialog has errors", function() {
            beforeEach(function() {
                spyOn(this.dialog.model, "clearErrors");
            });

            it("clears any errors on the model when the dialog is closed", function() {
                this.dialog.model.errors = { name: "wrong name" };
                this.dialog.$("button.cancel").click();
                expect(this.dialog.model.clearErrors).toHaveBeenCalled();
            });
        });

        describe("switching between new table and existing table", function() {
            context("switching from new to existing", function() {
                beforeEach(function() {
                    this.dialog.$(".new_table input:radio").prop("checked", true).change();
                    this.dialog.$(".existing_table input:radio").prop("checked", false);
                    spyOn(this.dialog, 'clearErrors');
                    this.dialog.$(".new_table input:radio").prop("checked", false);
                    this.dialog.$(".existing_table input:radio").prop("checked", true).change();
                });

                it("clears the errors", function() {
                    expect(this.dialog.clearErrors).toHaveBeenCalled();
                });

                it("sets the time fields to the model defaults", function() {
                    expect(this.dialog.$('select.hours')).toHaveValue(this.dialog.model.startTime().toString("h"));
                });
            });
            context("switching from existing to new", function() {
                beforeEach(function() {
                    this.dialog.$(".new_table input:radio").prop("checked", false);
                    this.dialog.$(".existing_table input:radio").prop("checked", true).change();
                    spyOn(this.dialog, 'clearErrors');
                    this.dialog.$(".new_table input:radio").prop("checked", true).change();
                    this.dialog.$(".existing_table input:radio").prop("checked", false);
                });

                it("clears the errors", function() {
                    expect(this.dialog.clearErrors).toHaveBeenCalled();
                });
            });
        });
    });

    describe("editing an existing schedule", function() {
        beforeEach(function() {
            this.importSchedule.set({
                truncate: true,
                sampleCount: 200,
                id:1234,
                startDatetime:"2013-02-21T13:30:00Z",
                endDate:"2013-05-27",
                frequency:"hourly",
                toTable:"my_table",
                newTable: false
            });
            this.dialog = new chorus.dialogs.ImportScheduler({
                dataset: this.dataset,
                workspace: this.workspace,
                action: "edit_schedule"
            });

        });

        context("and the destination is a new table", function() {
            beforeEach(function() {
                this.importSchedule.set({newTable: true});
                this.server.completeFetchFor(this.dataset.getImportSchedules(), [this.importSchedule]);
                this.dialog.render();
            });

            it("should show the schedule controls", function() {
                expect(this.dialog.$(".schedule_widget")).toExist();
            });

            it("should have a truncate checkbox", function() {
                expect(this.dialog.$(".truncate")).toExist();
            });

            it("initially has no errors", function() {
                expect(this.dialog.$(".has_error")).not.toExist();
            });

            it("has the right title", function() {
                expect(this.dialog.title).toMatchTranslation("import.title_edit_schedule");
            });

            it("has a submit button with the right text", function() {
                expect(this.dialog.$("button.submit").text()).toMatchTranslation("actions.save_changes");
            });

            it("has the right radio button selected", function() {
                expect(this.dialog.$("input[type='radio']#import_scheduler_existing_table")).not.toBeChecked();
                expect(this.dialog.$("input[type='radio']#import_scheduler_new_table")).toBeChecked();
            });

            it("pre-populates the table name", function() {
                expect(this.dialog.$(".new_table input.name").val()).toBe("my_table");
            });
        });

        context("and the destination is an existing Table", function() {
            beforeEach(function () {
                this.importSchedule.set({newTable: false});
                this.server.completeFetchFor(this.dataset.getImportSchedules(), [this.importSchedule]);
                this.dialog.render();
            });

            it("should show the schedule controls", function() {
                expect(this.dialog.$(".schedule_widget")).toExist();
            });

            it("should have a truncate checkbox", function() {
                expect(this.dialog.$(".truncate")).toExist();
            });

            it("has the right title", function () {
                expect(this.dialog.title).toMatchTranslation("import.title_edit_schedule");
            });

            it("has a submit button with the right text", function () {
                expect(this.dialog.$("button.submit").text()).toMatchTranslation("actions.save_changes");
            });

            it("has the right radio button selected", function () {
                expect(this.dialog.$("input[type='radio']#import_scheduler_existing_table")).toBeChecked();
                expect(this.dialog.$("input[type='radio']#import_scheduler_new_table")).not.toBeChecked();
            });

            it("pre-populates the schedule fields with the import's settings", function () {
                expect(this.dialog.$(".start input[name='year']").val()).toBe("2013");
                expect(this.dialog.$(".start input[name='month']").val()).toBe("2");
                expect(this.dialog.$(".start input[name='day']").val()).toBe("21");

                expect(this.dialog.$(".hours").val()).toBe("5");
                expect(this.dialog.$(".minutes").val()).toBe("30");
                expect(this.dialog.$(".ampm").val()).toBe("AM");

                expect(this.dialog.$(".end input[name='year']").val()).toBe("2013");
                expect(this.dialog.$(".end input[name='month']").val()).toBe("5");
                expect(this.dialog.$(".end input[name='day']").val()).toBe("27");
            });

            it("pre-populates the destination table and truncation fields with the import's settings", function () {
                expect(this.dialog.$(".existing_table a.dataset_picked").text()).toBe("my_table");
                expect(this.dialog.$(".truncate")).toBeChecked();
            });

            it("pre-populates the row limit", function () {
                expect(this.dialog.$("input[name='limit_num_rows']")).toBeChecked();
                expect(this.dialog.$("input[name='sampleCount']").val()).toBe("200");
            });

            it("pre-populates the row limit to 500 when row limit is undefined", function () {
                this.dialog.model.unset("sampleCount");
                this.dialog.render();
                expect(this.dialog.$("input[name='sampleCount']").val()).toBe("500");
            });

            it("has the right table", function() {
                expect(this.dialog.getNewModelAttrs().toTable).toBe(this.importSchedule.destination().name());
            });

            describe("submitting the form", function () {
                beforeEach(function () {
                    this.dialog.$("input[name='limit_num_rows']").prop("checked", false);
                    this.dialog.$("input[name='sampleCount']").val("201");
                    this.dialog.$("button.submit").click();
                });

                it("has the right loading text in the submit button", function () {
                    expect(this.dialog.$("button.submit").text()).toMatchTranslation("actions.saving");
                });

                it('correctly sets sampleCount to undefined when limit_num_rows is unchecked', function () {
                    expect(this.server.lastUpdate().params()["dataset_import_schedule[sample_count]"]).toBe("");
                });

                context("when the save completes", function () {
                    beforeEach(function () {
                        spyOnEvent(this.dataset, 'change');
                        spyOn(chorus.PageEvents, 'broadcast');
                        spyOn(chorus, "toast");
                        spyOn(this.dialog, "closeModal");
                        this.dialog.model.trigger("saved");
                    });

                    it("displays the right toast message", function () {
                        expect(chorus.toast).toHaveBeenCalledWith("import.schedule.toast");
                    });

                    it("triggers a importSchedule:changed event", function () {
                        expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith("importSchedule:changed", this.dialog.model);
                    });

                    it("triggers change on the dataset", function () {
                        expect('change').toHaveBeenTriggeredOn(this.dataset);
                    });
                });

                context("and the save is not successful", function () {
                    beforeEach(function () {
                        this.server.lastUpdate().failUnprocessableEntity({
                            fields: {
                                to_table: { SOME_FAKE_ERROR: {}}
                            }
                        });
                    });

                    it("should display the errors for the model", function() {
                        expect(this.dialog.$(".errors li")).toExist();
                    });
                });
            });
        });
    });
});
