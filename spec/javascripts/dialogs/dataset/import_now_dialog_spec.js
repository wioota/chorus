describe("chorus.dialogs.ImportNow", function () {
    beforeEach(function () {
        this.dataset = rspecFixtures.workspaceDataset.datasetTable();
        this.importSchedules = rspecFixtures.datasetImportScheduleSet();
        this.importSchedules.attributes = {
            datasetId: this.dataset.get('id'),
            workspaceId: this.dataset.get("workspace").id
        };
        this.importSchedule = this.importSchedules.at(0);
        this.importSchedule.set({
            datasetId: this.dataset.get('id'),
            workspaceId: this.dataset.get('workspace').id,
            destinationDatasetId: 789
        });
        this.workspace = rspecFixtures.workspace(this.dataset.get('workspace'));
        this.importSchedule.unset('sampleCount');


        this.dialog = new chorus.dialogs.ImportNow({
            dataset: this.dataset,
            workspace: this.workspace,
            action: "import_now"
        });
    });

    context("with an existing import", function () {
            beforeEach(function () {
            this.importSchedule.set({
                destinationTable: "foo",
                objectName: "bar"
            });
            this.server.completeFetchFor(this.dataset.getImportSchedules(), this.importSchedules.models);
            spyOn(this.dialog.model, "isNew").andReturn(false);
            this.dialog.render();
            this.dialog.$(".new_table input.name").val("good_table_name").trigger("keyup");
            expect(this.dialog.$("button.submit")).toBeEnabled();
        });

        it("does a post when the form is submitted", function () {
            this.dialog.$("button.submit").click();
            expect(this.server.lastCreate().url).toContain('import');
        });

        it("should not have a truncate checkbox for a new table", function () {
            expect(this.dialog.$("#import_scheduler_truncate_new")).not.toExist();
        });

        context("when 'Import into Existing Table' is checked", function () {
            beforeEach(function () {
                this.dialog.$(".new_table input:radio").prop("checked", false);
                this.dialog.$(".existing_table input:radio").prop("checked", true).change();
            });

            it("should enable the select", function () {
                expect(this.dialog.$(".existing_table a.dataset_picked")).not.toHaveClass("hidden");
                expect(this.dialog.$(".existing_table span.dataset_picked")).toHaveClass("hidden");
            });

            context("when clicking the dataset picker link", function () {
                beforeEach(function () {
                    stubModals();
                    this.dialog.$(".existing_table a.dataset_picked").click();
                });

                it("should have a link to the dataset picker dialog", function () {
                    expect(this.dialog.$(".existing_table a.dataset_picked")).toContainTranslation("dataset.import.select_dataset");
                });

                it("should set the pre-selected dataset if there is one", function () {
                    expect(chorus.modal.options.defaultSelection.attributes).toEqual(this.importSchedule.destination().attributes);
                });
            });
        });
    });

    context("without an existing import", function () {
        beforeEach(function () {
            this.importSchedule.set({
                toTable: null
            });
            this.server.completeFetchFor(this.dataset.getImportSchedules(), []);
            this.dialog.render();
        });

        it("should hide the schedule controls", function () {
            expect(this.dialog.$(".schedule_widget")).not.toExist();
        });

        it("should have the correct title", function () {
            expect(this.dialog.title).toMatchTranslation("import.title");
        });

        it("should have the right submit button text", function () {
            expect(this.dialog.submitText).toMatchTranslation("import.begin");
        });

        it("should initialize its model with the correct datasetId and workspaceId", function () {
            expect(this.dialog.model.get("datasetId")).toBe(this.dataset.get("id"));
            expect(this.dialog.model.get("workspaceId")).toBe(this.dataset.get("workspace").id);
        });

        it("should display the import destination", function () {
            expect(this.dialog.$(".destination")).toContainTranslation("import.destination", {canonicalName: this.workspace.sandbox().schema().canonicalName()});
        });

        it("should have a 'Begin Import' button", function () {
            expect(this.dialog.$("button.submit")).toContainTranslation("import.begin");
        });

        it("should have an 'Import Into New Table' radio button", function () {
            expect(this.dialog.$(".new_table label")).toContainTranslation("import.new_table");
        });

        it("should have a 'Limit Rows' checkbox", function () {
            expect(this.dialog.$(".new_table .limit label")).toContainTranslation("import.limit_rows");
            expect(this.dialog.$(".new_table .limit input:checkbox").prop("checked")).toBeFalsy();
        });

        it("should not have a truncate checkbox for a new table", function () {
            expect(this.dialog.$("#import_scheduler_truncate_new")).not.toExist();
        });

        it("should have a textfield for the 'Limit Rows' value", function () {
            expect(this.dialog.$(".new_table .limit input:text")).toBeDisabled();
        });

        it("should have a text entry for new table name", function () {
            expect(this.dialog.$(".new_table .name")).toBeEnabled();
        });

        it("should have an import into existing table radio button", function () {
            expect(this.dialog.$(".existing_table label")).toContainTranslation("import.existing_table");
        });

        it("should not have anything after 'Import into an existing table' for existing tables", function () {
            expect(this.dialog.$(".existing_table a.dataset_picked")).toHaveClass("hidden");
            expect(this.dialog.$(".existing_table span.dataset_picked")).toHaveClass("hidden");
        });

        it("should have the import button disabled by default", function () {
            expect(this.dialog.$("button.submit")).toBeDisabled();
        });

        it("should enable the import button when a name is typed into the toTable input", function () {
            this.dialog.$(".new_table input.name").val("newTable").trigger("keyup");
            expect(this.dialog.$("button.submit")).toBeEnabled();
        });

        context("when 'Import into Existing Table' is checked", function () {
            beforeEach(function () {
                this.dialog.$(".new_table input:radio").prop("checked", false);
                this.dialog.$(".existing_table input:radio").prop("checked", true).change();
            });

            it("should enable the select", function () {
                expect(this.dialog.$(".existing_table a.dataset_picked")).not.toHaveClass("hidden");
                expect(this.dialog.$(".existing_table span.dataset_picked")).toHaveClass("hidden");
            });

            it("should disable the submit button by default", function () {
                expect(this.dialog.$("button.submit")).toBeDisabled();
            });

            context("when clicking the dataset picker link", function () {
                beforeEach(function () {
                    stubModals();
                    spyOn(chorus.Modal.prototype, 'launchSubModal').andCallThrough();
                    spyOn(this.dialog, "datasetsChosen").andCallThrough();
                    this.dialog.$(".existing_table a.dataset_picked").click();
                });

                it("should have a link to the dataset picker dialog", function () {
                    expect(this.dialog.$(".existing_table a.dataset_picked")).toContainTranslation("dataset.import.select_dataset");
                });

                it("should launch the dataset picker dialog", function () {
                    expect(chorus.Modal.prototype.launchSubModal).toHaveBeenCalled();
                });

                describe("when a dataset is selected", function () {
                    var datasets;
                    beforeEach(function () {
                        datasets = [rspecFixtures.workspaceDataset.datasetTable({ objectName: "myDatasetWithAReallyReallyLongName" })];
                        chorus.modal.trigger("datasets:selected", datasets);
                    });

                    it("should show the selected dataset in the link, ellipsized", function () {
                        expect(this.dialog.datasetsChosen).toHaveBeenCalled()
                        expect(this.dialog.$(".existing_table a.dataset_picked")).toContainText("myDatasetWithAReally...");
                    });

                    it("stores the un-ellipsized dataset name on the link item", function () {
                        expect(this.dialog.$(".existing_table a.dataset_picked").data("dataset")).toBe("myDatasetWithAReallyReallyLongName");
                    });

                    it("should re-enable the submit button", function () {
                        expect(this.dialog.$("button.submit")).toBeEnabled();
                    });

                    describe("clicking the 'import' button", function () {
                        beforeEach(function () {
                            this.dialog.$("button.submit").click();
                        });

                        it("sends the correct dataset name", function () {
                            expect(this.server.lastCreate().params()["dataset_import[to_table]"]).toBe("myDatasetWithAReallyReallyLongName");
                        });
                    });

                    context("and then 'import into new table is checked", function () {
                        beforeEach(function () {
                            this.dialog.$(".existing_table input:radio").prop("checked", false);
                            this.dialog.$(".new_table input:radio").prop("checked", true).change();
                        });

                        it("still shows the selected table name in the existing table section", function () {
                            expect(this.dialog.$(".existing_table span.dataset_picked")).not.toHaveClass('hidden');
                        });
                    });
                });
            });

            context("and the form is submitted", function () {
                beforeEach(function () {
                    this.dialog.$(".existing_table .truncate").prop("checked", true).change();
                    this.dialog.$(".existing_table a.dataset_picked").text("a");
                    this.dialog.onInputFieldChanged();

                    this.dialog.$("button.submit").click();
                });

                it("should save the model", function () {
                    expect(this.server.lastCreateFor(this.dialog.model).params()["dataset_import[truncate]"]).toBe("true");
                });
            });

            context("when 'Import into New Table' is checked and a valid name is entered", function () {
                beforeEach(function () {
                    this.dialog.$(".new_table input:radio").prop("checked", true).change();
                    this.dialog.$(".existing_table input:radio").prop("checked", false).change();
                    this.dialog.$(".new_table input.name").val("Foo").trigger("keyup");
                });

                it("should disable the 'Existing table' link", function () {
                    expect(this.dialog.$(".existing_table a.dataset_picked")).toHaveClass("hidden");
                });

                context("checking the limit rows checkbox", function () {
                    beforeEach(function () {
                        this.dialog.$(".new_table .limit input:checkbox").prop("checked", true).change();
                    });

                    it("should enable the limit text input", function () {
                        expect(this.dialog.$(".new_table .limit input:text")).toBeEnabled();
                    });

                    context("entering a valid row limit", function () {
                        beforeEach(function () {
                            this.dialog.$(".new_table .limit input:text").val("345").trigger("keyup");
                        });

                        it("should enable the submit button when a row limit is entered", function () {
                            expect(this.dialog.$("button.submit")).toBeEnabled();
                        });
                    });
                });

                context("when the inputs are filled with valid values", function () {
                    beforeEach(function () {
                        this.dialog.$(".new_table input.name").val("good_table_name").trigger("keyup");
                    });

                    it("enables the submit button", function () {
                        expect(this.dialog.$("button.submit")).toBeEnabled();
                    });

                    context("when the form is submitted", function () {
                        beforeEach(function () {
                            this.dialog.$("button.submit").click();
                        });

                        it("should save the model", function () {
                            expect(this.server.lastCreateFor(this.dialog.model)).toBeDefined();
                        });

                        it("should put the submit button in the loading state", function () {
                            expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
                            expect(this.dialog.$("button.submit")).toContainTranslation("import.importing");
                        });

                        context("and the save is successful", function () {
                            beforeEach(function () {
                                spyOn(chorus, "toast");
                                spyOn(this.dialog, "closeModal");
                                this.server.completeSaveFor(this.dialog.model);
                            });

                            it("should display a toast", function () {
                                expect(chorus.toast).toHaveBeenCalledWith("import.success");
                            });

                            it("should close the dialog", function () {
                                expect(this.dialog.closeModal).toHaveBeenCalled();
                            });

                        });

                        context("and the save is not successful", function () {
                            beforeEach(function () {
                                this.server.lastCreate().failUnprocessableEntity();
                            });

                            it("should not display the loading spinner", function () {
                                expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
                            });
                        });
                    });
                });
            });
        });
    });
});
