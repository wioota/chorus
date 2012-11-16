describe("chorus.presenters.DatasetSidebar", function() {
    describe("ellipsize", function() {
        it("ellipsizes a long string", function() {
            expect(chorus.presenters.DatasetSidebar.prototype.ellipsize("Hello my name is very long")).toBe("Hello my nam...");
        });

        it("doesn't ellipsize a short string", function() {
            expect(chorus.presenters.DatasetSidebar.prototype.ellipsize("Hello")).toBe("Hello");
        });

        it("returns an empty string when passed nothing", function() {
            expect(chorus.presenters.DatasetSidebar.prototype.ellipsize(undefined)).toBe("");
        });
    });

    describe("_linkToModel", function() {
        it("returns a link to a model", function() {
            var model = new chorus.models.User({ id: 5, firstName: "Tom", lastName: "Wood" });
            expect(chorus.presenters.DatasetSidebar.prototype._linkToModel(model)).toEqual({ string: '<a href="#/users/5" title="Tom Wood">Tom Wood</a>'});
        });
    });

    describe("the context", function() {
        context("with a regular dataset", function() {
            var presenter, resource;
            beforeEach(function() {
                resource = rspecFixtures.dataset();
                presenter = new chorus.presenters.DatasetSidebar(resource);
            });

            it("returns everything", function() {
                expect(presenter.canExport()).toBeFalsy();
                expect(presenter.hasImport()).toBeFalsy();
                expect(presenter.displayEntityType()).toEqual("table");
                expect(presenter.isChorusView()).toBeFalsy();
                expect(presenter.noCredentials()).toBeFalsy();
                expect(presenter.noCredentialsWarning()).not.toBeEmpty();
                expect(presenter.typeString()).not.toBeEmpty();
                expect(presenter.workspaceId()).not.toBeEmpty();
                expect(presenter.hasSandbox()).toBeFalsy();
                expect(presenter.activeWorkspace()).toBeFalsy();
                expect(presenter.isDeleteable()).toBeFalsy();
                expect(presenter.deleteMsgKey()).not.toBeEmpty();
                expect(presenter.deleteTextKey()).not.toBeEmpty();
                expect(presenter.isImportConfigLoaded()).toBeFalsy();
                expect(presenter.hasSchedule()).toBeFalsy();
                expect(presenter.nextImport()).toBeFalsy();
                expect(presenter.inProgressText()).not.toBeEmpty();
                expect(presenter.importInProgress()).not.toBeEmpty();
                expect(presenter.importFailed()).not.toBeEmpty();
                expect(presenter.lastImport()).not.toBeEmpty();
                expect(presenter.canAnalyze()).not.toBeEmpty();
            });

            describe("#nextImport", function(){
                context("No next import", function() {
                    beforeEach(function() {
                        var schedule = rspecFixtures.datasetImportScheduleSet().last();
                        schedule.set('nextImportAt', null);
                        spyOn(resource, 'importSchedule').andReturn(schedule);
                    });

                    it("displays the tablename", function() {
                        workspace_dataset_model = presenter.nextImport();
                        this.nextImportLink = presenter.nextImport().string;
                        expect(this.nextImportLink).toMatchTranslation('import.no_next_import');

                    });
                });

                context("The destination dataset exists", function() {
                    beforeEach(function() {
                        var schedule = rspecFixtures.datasetImportScheduleSet().last();
                        schedule.set({
                           toTable: "My New Table",
                           workspaceId: 13,
                           destinationDatasetId: 234,
                           nextImportAt: "2013-09-07T06:00:00Z"
                        });
                        spyOn(resource, "importSchedule").andReturn(schedule);
                    });

                    it("displays the tablename", function() {
                        workspace_dataset_model = presenter.nextImport();
                        this.nextImportLink = presenter.nextImport().string;
                        expect(this.nextImportLink).toMatchTranslation('import.next_import', {
                            nextTime: chorus.helpers.relativeTimestamp("2013-09-07T06:00:00Z"),
                            tableRef: "<a href=\"#/workspaces/13/datasets/234\" title=\"My New Table\">My New Table</a>"
                        });
                    });
                });
                context("The destination dataset does not yet exist", function() {
                    beforeEach(function() {
                        var schedule = rspecFixtures.datasetImportScheduleSet().last();
                        schedule.set({
                            toTable: "My New Table",
                            workspaceId: 13,
                            nextImportAt: "2013-09-07T06:00:00Z"
                        });
                        spyOn(resource, "importSchedule").andReturn(
                            schedule
                        );
                    });

                    it("displays the tablename without the link", function() {
                        workspace_dataset_model = presenter.nextImport();
                        this.nextImportLink = presenter.nextImport().string;
                        expect(this.nextImportLink).toMatchTranslation('import.next_import', {
                            nextTime: chorus.helpers.relativeTimestamp("2013-09-07T06:00:00Z"),
                            tableRef: "My New Table"
                        });
                    });
                });
            });

            describe("#lastImport", function() {
                context("for a source table", function() {
                    beforeEach(function() {
                        this.import = rspecFixtures.datasetImportSet().last();
                        this.import.set({
                            sourceDatasetId: resource.get('id'),
                            completedStamp: Date.parse("Today - 33 days").toJSONString(),
                            success: true
                        });
                    });

                    describe("unfinished import", function() {
                        beforeEach(function() {
                            delete this.import.attributes.completedStamp;
                            this.spy = spyOn(resource, 'lastImport').andReturn(
                                this.import
                            );
                        });
                        it("has inProgressText and lastImport", function() {
                            expect(presenter.inProgressText()).toMatch("Import into ");
                            expect(presenter.importInProgress()).toBeTruthy();
                            expect(presenter.importFailed()).toBeFalsy();
                            expect(presenter.lastImport()).toMatch("Import started");
                        });

                        it("doesn't display the link in inProgressText when table does not exist yet ", function() {
                            expect(presenter.inProgressText().toString()).toMatchTranslation("import.in_progress", { tableLink: this.import.destination().name()});
                        });

                        context("when importing to an existing table", function() {
                            beforeEach(function() {
                                delete this.import.attributes.completedStamp;
                                this.import.set({destinationDatasetId: 2});
                                this.spy.andReturn(
                                    this.import
                                );
                            })
                            it("display inProgressText with a link to the table", function() {
                                expect(presenter.inProgressText().toString()).toMatchTranslation("import.in_progress", { tableLink: presenter._linkToModel(this.import.destination(), this.import.destination().name())});
                            });

                        })
                    });

                    describe("successfully finished import", function() {
                        beforeEach(function() {
                            spyOn(resource, 'lastImport').andReturn(
                                this.import
                            );
                        });

                        it("has normal lastImport text", function() {
                            expect(presenter.importInProgress()).toBeFalsy();
                            expect(presenter.importFailed()).toBeFalsy();
                            expect(presenter.lastImport()).toMatch("Imported 1 month ago into");
                        });
                    });

                    describe("failed import", function() {
                        beforeEach(function() {
                            this.import.attributes.success = false;
                            spyOn(resource, 'lastImport').andReturn(
                                this.import
                            );
                        });

                        it("has failed lastImport text", function() {
                            expect(presenter.importInProgress()).toBeFalsy();
                            expect(presenter.importFailed()).toBeTruthy();
                            expect(presenter.lastImport()).toMatch("Import failed 1 month ago into");
                        });
                    });
                });

                context("for a sandbox table", function() {
                    beforeEach(function () {
                        this.import = rspecFixtures.datasetImportSet().first();
                        this.import.set({
                            sourceDatasetId: resource.get('id') + 1,
                            completedStamp: Date.parse("Today - 33 days").toJSONString(),
                            success: true
                        });
                    });

                    describe("unfinished import", function() {
                        beforeEach(function() {
                            delete this.import.attributes.completedStamp;
                            spyOn(resource, 'lastImport').andReturn(
                                this.import
                            );
                        });
                        it("has inProgressText and lastImport", function() {
                            expect(presenter.inProgressText().toString()).toMatchTranslation("import.in_progress_into", { tableLink: presenter._linkToModel(this.import.source(), this.import.source().name())});
                            expect(presenter.importInProgress()).toBeTruthy();
                            expect(presenter.importFailed()).toBeFalsy();
                            expect(presenter.lastImport()).toMatch("Import started");
                        });
                    });

                    describe("successfully finished import", function() {
                        beforeEach(function() {
                            spyOn(resource, 'lastImport').andReturn(
                                this.import
                            );
                        });

                        it("has normal lastImport text", function() {
                            expect(presenter.importInProgress()).toBeFalsy();
                            expect(presenter.importFailed()).toBeFalsy();
                            expect(presenter.lastImport()).toMatch("Imported 1 month ago from");
                        });
                    });

                    describe("import from a file", function() {
                        beforeEach(function () {
                            this.import.unset("sourceDatasetId");
                            this.import.unset("sourceDatasetName");
                            this.import.set("fileName", "foo.csv");
                            spyOn(resource, 'lastImport').andReturn(
                                this.import
                            );
                        });

                        it("shows last import from file text", function() {
                            expect(presenter.importInProgress()).toBeFalsy();
                            expect(presenter.importFailed()).toBeFalsy();
                            expect(presenter.lastImport()).toMatch("Imported 1 month ago from");
                            expect(presenter.lastImport()).toMatch("foo.csv");
                        });
                    });

                    describe("failed import", function() {
                        beforeEach(function() {
                            this.import.attributes.success = false;
                            spyOn(resource, 'lastImport').andReturn(
                                this.import
                            );
                        });

                        it("has failed lastImport text", function() {
                            expect(presenter.importInProgress()).toBeFalsy();
                            expect(presenter.importFailed()).toBeTruthy();
                            expect(presenter.lastImport()).toMatch("Import failed 1 month ago from");
                        });
                    });
                });
            })
        });

        context("with a workspace table", function() {
            var presenter, sidebar, resource;
            beforeEach(function() {
                resource = rspecFixtures.workspaceDataset.datasetTable();
                resource.workspace()._sandbox = new chorus.models.Sandbox({ id : 123 })
                presenter = new chorus.presenters.DatasetSidebar(resource);
            });

            it("returns everything", function() {
                expect(presenter.workspaceArchived()).toBeFalsy();
                expect(presenter.hasSandbox()).toBeTruthy();
                expect(presenter.workspaceId()).not.toBeEmpty();
                expect(presenter.activeWorkspace()).toBeTruthy();
            });
        });
    });
});
