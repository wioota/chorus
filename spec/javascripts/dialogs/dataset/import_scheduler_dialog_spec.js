describe("chorus.dialogs.ImportScheduler", function() {
    beforeEach(function() {
        this.dataset = rspecFixtures.workspaceDataset.datasetTable();
        this.importSchedules = rspecFixtures.datasetImportScheduleSet();
        this.importSchedules.attributes = {
            datasetId: this.dataset.get('id'),
            workspaceId: this.dataset.get("workspace").id
        };
        this.importSchedule = this.importSchedules.at(0);
        this.importSchedule.set({
            datasetId: this.dataset.get('id'),
            workspaceId: this.dataset.get('workspace').id
        });
        this.workspace = rspecFixtures.workspace(this.dataset.get('workspace'));
        this.importSchedule.unset('sampleCount');
        this.importSchedule.unset('id');
    });

    describe("#getNewModelAttrs", function() {
        describe("when creating a new schedule", function() {
            beforeEach(function() {
                this.dialog = new chorus.dialogs.ImportScheduler({
                    dataset: this.dataset,
                    workspace: this.workspace,
                    action: "create_schedule"
                });
                this.server.completeFetchFor(this.importSchedules);
                this.dialog.$(".new_table input:radio").prop("checked", false);
                this.dialog.$(".existing_table input:radio").prop("checked", true).change();
                this.attrs = this.dialog.getNewModelAttrs();
            });

            it("takes the workspace from the options passed", function() {
                expect(this.dialog.workspace).toBe(this.workspace);
            });

            it("has the 'importType' parameter set to 'schedule'", function() {
                expect(this.attrs.importType).toBe("schedule");
            });
        });

        describe("when editing an existing schedule", function() {
            beforeEach(function() {
                this.dialog = new chorus.dialogs.ImportScheduler({
                    dataset: this.dataset,
                    workspace: this.workspace,
                    action: "edit_schedule"
                });
                this.server.completeFetchFor(this.importSchedules);
                this.dialog.$(".new_table input:radio").prop("checked", false);
                this.dialog.$(".existing_table input:radio").prop("checked", true).change();
                this.dialog.$(".dataset_picked").text("my_existing_table");
                this.dialog.$(".dataset_picked").data("dataset", "my_existing_table");
                this.attrs = this.dialog.getNewModelAttrs();
            });

            it("has the 'importType' parameter set to 'schedule'", function() {
                expect(this.attrs.importType).toBe("schedule");
            });

            it("has the right table", function() {
                expect(this.attrs.toTable).toBe("my_existing_table");
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
        });
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

        it("should have a truncate checkbox for a new table", function() {
            expect(this.dialog.$("#import_scheduler_truncate_new")).toExist();
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
            expect(this.dialog.$('.new_table select.hours')).toHaveValue(this.dialog.model.startTime().toString("h"));
        });

        context("when 'Import into New Table' is checked", function() {
            beforeEach(function() {
                this.dialog.$(".new_table input:radio").prop("checked", true).change();
            });

            itShouldHaveAllTheFields(".new_table");

            it("doesn't show 'Select a table' menu/link", function() {
                expect(this.dialog.$("span.dataset_picked")).toHaveClass("hidden");
            });
        });

        context("when 'Import into Existing Table' is checked", function() {
            beforeEach(function() {
                this.dialog.activeScheduleView.enable.reset();
                this.dialog.$(".new_table input:radio").prop("checked", false);
                this.dialog.$(".existing_table input:radio").prop("checked", true).change();
            });

            itShouldHaveAllTheFields(".existing_table");
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

                    this.dialog.activeScheduleView.$(".start input[name='year']").val("2012");
                    this.dialog.activeScheduleView.$(".start input[name='month']").val("02");
                    this.dialog.activeScheduleView.$(".start input[name='day']").val("29");

                    this.dialog.activeScheduleView.$(".end input[name='year']").val("2012");
                    this.dialog.activeScheduleView.$(".end input[name='month']").val("03");
                    this.dialog.activeScheduleView.$(".end input[name='day']").val("21");

                    this.dialog.activeScheduleView.$("select.ampm").val("PM");
                    this.dialog.activeScheduleView.$("select.hours").val("12");
                    this.dialog.activeScheduleView.$("select.minutes").val("09");

                    expect(this.dialog.$("button.submit")).toBeEnabled();

                    this.dialog.$("button.submit").click();
                });

                it("should put the values in the correct API form fields", function() {
                    var params = this.server.lastCreate().params();
                    expect(params["dataset_import_schedule[truncate]"]).toBe("false");
                    expect(params["dataset_import_schedule[sample_count]"]).toBe("123");
                    expect(params["dataset_import_schedule[start_datetime]"]).toBe("2012-02-29 12:09:00.0");
                    expect(params["dataset_import_schedule[end_date]"]).toBe("2012-03-21")
                });
            });

            context("when the row limit is not checked and the form is submitted", function() {
                beforeEach(function() {
                    this.dialog.$("input:checked[name='truncate']").prop("checked", false).change();

                    this.dialog.$("select[name='toTable']").eq(0).attr("selected", true);

                    this.dialog.$(".existing_table a.dataset_picked").text("a");

                    this.dialog.$("input[name='limit_num_rows']").prop("checked", false)

                    this.dialog.activeScheduleView.$(".start input[name='year']").val("2012");
                    this.dialog.activeScheduleView.$(".start input[name='month']").val("02");
                    this.dialog.activeScheduleView.$(".start input[name='day']").val("29");

                    this.dialog.activeScheduleView.$(".end input[name='year']").val("2012");
                    this.dialog.activeScheduleView.$(".end input[name='month']").val("03");
                    this.dialog.activeScheduleView.$(".end input[name='day']").val("21");

                    this.dialog.activeScheduleView.$("select.ampm").val("PM");
                    this.dialog.activeScheduleView.$("select.hours").val("12");
                    this.dialog.activeScheduleView.$("select.minutes").val("09");

                    this.dialog.onInputFieldChanged();
                    expect(this.dialog.$("button.submit")).toBeEnabled();

                    this.dialog.$("button.submit").click();
                });

                it("should put the values in the correct API form fields", function() {
                    var params = this.server.lastCreate().params();
                    expect(params["dataset_import_schedule[truncate]"]).toBe("false");
                    expect(params["dataset_import_schedule[sample_count]"]).toBe("");
                    expect(params["dataset_import_schedule[start_datetime]"]).toBe("2012-02-29 12:09:00.0");
                    expect(params["dataset_import_schedule[end_date]"]).toBe("2012-03-21");
                });

            });
        }

        describe("switching between new table and existing table", function() {
            context("switching from new to existing", function() {
                beforeEach(function() {
                    this.dialog.$(".new_table input:radio").prop("checked", true).change();
                    this.dialog.$(".existing_table input:radio").prop("checked", false);
                    spyOn(this.dialog, 'clearErrors');
                    this.dialog.$(".new_table input:radio").prop("checked", false);
                    this.dialog.$(".existing_table input:radio").prop("checked", true).change();
                })

                it("clears the errors", function() {
                    expect(this.dialog.clearErrors).toHaveBeenCalled();
                })

                it("sets the time fields to the model defaults", function() {
                    expect(this.dialog.$('.existing_table select.hours')).toHaveValue(this.dialog.model.startTime().toString("h"));
                });
            })
            context("switching from existing to new", function() {
                beforeEach(function() {
                    this.dialog.$(".new_table input:radio").prop("checked", false);
                    this.dialog.$(".existing_table input:radio").prop("checked", true).change();
                    spyOn(this.dialog, 'clearErrors');
                    this.dialog.$(".new_table input:radio").prop("checked", true).change();
                    this.dialog.$(".existing_table input:radio").prop("checked", false);
                })

                it("clears the errors", function() {
                    expect(this.dialog.clearErrors).toHaveBeenCalled();
                })
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

        context("and the toTable is not an existing Table", function() {
            beforeEach(function() {
                this.importSchedule.set({newTable: true});
                this.server.completeFetchFor(this.dataset.getImportSchedules(), [this.importSchedule]);
                this.dialog.render();
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

            it("has the right fieldset selected", function() {
                expect(this.dialog.$("input[type='radio']#import_scheduler_existing_table")).not.toBeChecked();
                expect(this.dialog.$("input[type='radio']#import_scheduler_new_table")).toBeChecked();
                expect(this.dialog.$(".existing_table fieldset")).toHaveClass("disabled");
                expect(this.dialog.$(".new_table fieldset")).not.toHaveClass("disabled");
            });

            it("pre-populates the table name", function() {
                expect(this.dialog.$(".new_table input.name").val()).toBe("my_table");
            })

            it("should have a truncate checkbox for a new table", function() {
                expect(this.dialog.$("#import_scheduler_truncate_new")).toExist();
            });
        });

        context("and the toTable is an existing Table", function() {
            beforeEach(function () {
                this.importSchedule.set({newTable: false});
                this.server.completeFetchFor(this.dataset.getImportSchedules(), [this.importSchedule]);
//                this.server.completeFetchFor(this.importSchedules);
                this.dialog.render();
            });

            it("has the right title", function () {
                expect(this.dialog.title).toMatchTranslation("import.title_edit_schedule");
            });

            it("has a submit button with the right text", function () {
                expect(this.dialog.$("button.submit").text()).toMatchTranslation("actions.save_changes");
            });

            it("has the right fieldset selected", function () {
                expect(this.dialog.$("input[type='radio']#import_scheduler_existing_table")).toBeChecked();
                expect(this.dialog.$("input[type='radio']#import_scheduler_new_table")).not.toBeChecked();
                expect(this.dialog.$(".existing_table fieldset")).not.toHaveClass("disabled");
                expect(this.dialog.$(".new_table fieldset")).toHaveClass("disabled");
            });

            it("should have a truncate checkbox for a new table", function () {
                expect(this.dialog.$("#import_scheduler_truncate_new")).toExist();
            });

            it("pre-populates the schedule fields with the import's settings", function () {
                expect(this.dialog.activeScheduleView.$(".start input[name='year']").val()).toBe("2013");
                expect(this.dialog.activeScheduleView.$(".start input[name='month']").val()).toBe("2");
                expect(this.dialog.activeScheduleView.$(".start input[name='day']").val()).toBe("21");

                expect(this.dialog.activeScheduleView.$(".hours").val()).toBe("5");
                expect(this.dialog.activeScheduleView.$(".minutes").val()).toBe("30");
                expect(this.dialog.activeScheduleView.$(".ampm").val()).toBe("AM");

                expect(this.dialog.activeScheduleView.$(".end input[name='year']").val()).toBe("2013");
                expect(this.dialog.activeScheduleView.$(".end input[name='month']").val()).toBe("5");
                expect(this.dialog.activeScheduleView.$(".end input[name='day']").val()).toBe("27");
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

            describe("submitting the form", function () {
                beforeEach(function () {
                    this.dialog.$("input[name='limit_num_rows']").prop("checked", false)
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
                    })
                });
            });
        });
    });

});
