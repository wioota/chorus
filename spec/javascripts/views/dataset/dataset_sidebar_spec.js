describe("chorus.views.DatasetSidebar", function() {
    beforeEach(function() {
        this.modalSpy = stubModals();
        this.view = new chorus.views.DatasetSidebar();
        this.view.render();
    });

    context("when it is disabled", function() {
        beforeEach(function() {
            this.view.disabled = true;
            spyOn(this.view, 'template');
            this.view.render();
        });

        it("does not actually render", function() {
            expect(this.view.template).not.toHaveBeenCalled();
        });
    });

    context("when no dataset is selected", function() {
        it("does not render the info section", function() {
            expect(this.view.$(".info")).not.toExist();
        });
    });

    context("when a dataset is selected", function() {
        beforeEach(function() {
            this.server.reset();
            this.dataset = rspecFixtures.workspaceDataset.sourceTable();
            chorus.PageEvents.broadcast("dataset:selected", this.dataset);
        });

        it("does not display the multiple selection section", function() {
            expect(this.view.$(".multiple_selection")).toHaveClass("hidden");
        });

        it("displays the selected dataset name", function() {
            expect(this.view.$(".name").text().trim()).toBe(this.dataset.get("objectName"));
        });

        context("when the statistics has not yet loaded", function() {
            it("displays the selected dataset type", function() {
                expect(this.view.$(".details").text().trim()).toBe('Source Table');
            });
        });

        context("when the statistics finish loading", function() {
            beforeEach(function() {
                spyOn(this.view, 'postRender');
                this.dataset.statistics().fetch();
                this.server.completeFetchFor(this.dataset.statistics());
            });

            it("should update the selected dataset type", function() {
                expect(this.view.postRender).toHaveBeenCalled();
            });
        });

        describe("activities", function() {
            it("fetches the activities for the dataset", function() {
                expect(this.dataset.activities()).toHaveBeenFetched();
            });

            it("prefers only the without_workspace type for the activity list", function() {
                expect(this.view.tabs.activity.options.displayStyle).toEqual(['without_workspace']);
            });

            context("when the activity fetch completes", function() {
                beforeEach(function() {
                    this.server.completeFetchFor(this.dataset.activities());
                });

                it("renders an activity list inside the tabbed area", function() {
                    expect(this.view.tabs.activity).toBeA(chorus.views.ActivityList);
                    expect(this.view.tabs.activity.el).toBe(this.view.$(".tabbed_area .activity_list")[0]);
                });
            });
        });

        describe("analyze table", function() {
            it("displays the analyze table action", function() {
                expect(this.view.$(".actions a.analyze")).toContainTranslation("dataset.actions.analyze")
            });

            it("does not display for a view", function() {
                this.dataset = rspecFixtures.dataset({objectType: "VIEW"});
                chorus.PageEvents.broadcast("dataset:selected", this.dataset);
                expect(this.view.$(".actions a.analyze")).not.toExist();
            });

            it("does not display the action for a external table", function() {
                this.dataset = newFixtures.workspaceDataset.externalTable();
                chorus.PageEvents.broadcast("dataset:selected", this.dataset);
                expect(this.view.$(".actions a.analyze")).not.toExist();
            });

            it("does not display the action for a hadoop external table", function() {
                this.dataset = fixtures.datasetHadoopExternalTable();
                chorus.PageEvents.broadcast("dataset:selected", this.dataset);
                expect(this.view.$(".actions a.analyze")).not.toExist();
            });

            context("when the run analyze link is clicked", function() {
                beforeEach(function() {
                    this.view.$(".actions a.analyze").click();
                });

                it("displays an alert dialog", function() {
                    expect(this.modalSpy).toHaveModal(chorus.alerts.Analyze);
                });
            });

            context("when the analyze:running event is broadcast", function() {
                it("re-fetches the dataset statistics", function() {
                    this.server.reset();
                    chorus.PageEvents.broadcast("analyze:running");
                    expect(this.server.lastFetchFor(this.view.resource.statistics())).toBeDefined();
                });
            });
        });

        context("when user does not have credentials", function() {
            beforeEach(function() {
                this.dataset.set({hasCredentials: false});
                this.view.render();
            });

            it("does not show the preview data link even when on a list page", function() {
                this.view.options.listMode = true;
                this.view.render();
                expect(this.view.$('.actions .dataset_preview')).not.toExist();
            });

            it("does not have the 'Import Now' action even if there's a workspace", function() {
                this.view.resource._workspace = rspecFixtures.workspace();
                this.view.render();
                expect(this.view.$(".actions .import_now")).not.toExist();
            });

            it("does not show the analyze table action", function() {
                expect(this.view.$(".actions a.analyze")).not.toExist();
            });

            it("shows a no-permissions message", function() {
                this.view.render();
                expect(this.view.$('.no_credentials')).toContainTranslation("dataset.credentials.missing.body", {
                    linkText: t("dataset.credentials.missing.linkText"),
                    instanceName: this.dataset.instance().name()
                });
            });

            context("clicking on the link to add credentials", function() {
                beforeEach(function() {
                    this.view.render();
                    this.view.$('.no_credentials a.add_credentials').click();
                });

                it("launches the InstanceAccount dialog", function() {
                    expect(chorus.modal).toBeA(chorus.dialogs.InstanceAccount);
                });

                context("saving the credentials", function() {
                    beforeEach(function() {
                        spyOn(chorus.router, "reload");
                        chorus.modal.$('input').val('stuff');
                        chorus.modal.$('form').submit();
                        this.server.completeSaveFor(chorus.modal.model);
                    });

                    it("reloads the current page", function() {
                        expect(chorus.router.reload).toHaveBeenCalled();
                    });
                });
            });
        });

        it("displays a download link", function() {
            expect(this.view.$("a.download")).toHaveData("dialog", "DatasetDownload");
            expect(this.view.$("a.download")).toHaveData("dataset", this.dataset);
            expect(this.view.$("a.download").text()).toMatchTranslation("actions.download");
        });

        context("when in list mode", function() {
            beforeEach(function() {
                this.view.options.listMode = true;
                this.view.render();
            });

            it("displays the 'Preview Data' link", function() {
                expect(this.view.$('.actions .dataset_preview')).toContainTranslation('actions.dataset_preview');
            });

            describe("when the 'Preview Data' link is clicked", function() {
                beforeEach(function() {
                    this.view.$(".dataset_preview").click();
                });

                it("displays the preview data dialog", function() {
                    expect(chorus.modal).toBeA(chorus.dialogs.DatasetPreview);
                });
            });
        });

        context("when not in list mode", function() {
            it("does not display the 'Preview Data' link", function() {
                expect(this.view.$('.actions .dataset_preview')).not.toExist();
            });
        });

        context("when there is an archived workspace", function() {
            beforeEach(function() {
                this.view.resource._workspace = rspecFixtures.workspace({ archivedAt: "2012-05-08T21:40:14Z", permission: ["update", "admin"] });
                this.view.options.listMode = true;
                this.view.render();
                this.dataset = rspecFixtures.workspaceDataset.datasetTable();
                this.dataset._workspace = this.view.resource._workspace;
                chorus.PageEvents.broadcast("dataset:selected", this.dataset);
                this.server.completeFetchFor(this.view.imports, []);
            });

            it("has no action links except for 'Preview Data' and 'Download'", function() {
                expect(this.view.$(".actions a").length).toBe(2);
                expect(this.view.$(".actions a.dataset_preview")).toExist();
                expect(this.view.$(".actions a.download")).toExist();
            });
        });

        context("when there is a workspace", function() {
            beforeEach(function() {
                this.view.resource._workspace = rspecFixtures.workspace();
                this.view.render();
            });

            context("and no dataset is selected", function() {
                beforeEach(function() {
                    chorus.PageEvents.broadcast("dataset:selected");
                });

                itShowsTheAppropriateDeleteLink(false)
                itDoesNotHaveACreateDatabaseViewLink();
            });

            it("doesn't display any import links by default", function() {
                expect(this.view.$("a.create_schedule, a.edit_schedule, a.import_now")).not.toExist();
            });

            context("when the dataset is a sandbox table or view", function() {
                beforeEach(function() {
                    this.dataset = rspecFixtures.workspaceDataset.datasetTable();
                    this.view.resource._workspace = rspecFixtures.workspace({ id: 6007, permission: ["update"] })
                    chorus.PageEvents.broadcast("dataset:selected", this.dataset);
                });

                itDoesNotShowTheDuplicateChorusViewLink();
                itShowsTheAppropriateDeleteLink(false);
                itDoesNotHaveACreateDatabaseViewLink();

                context("and the dataset has not received an import", function() {
                    beforeEach(function() {
                        this.server.completeFetchFor(this.view.imports, []);
                    });

                    it("doesn't display a 'import now' link", function() {
                        expect(this.view.$(".import_now")).not.toExist();
                    });
                });

                context("when the dataset has a last import (as a destination dataset)", function() {
                    beforeEach(function() {
                        this.imports = rspecFixtures.datasetImportSet();
                        this.lastImport = this.imports.last();
                        this.lastImport.set({
                            startedStamp: "2012-02-29T14:23:58Z",
                            completedStamp: "2012-02-29T14:23:59Z",
                            success: true,
                            toTable: this.dataset.name(),
                            destinationDatasetId: this.dataset.id,
                            sourceDatasetName: "sourcey",
                            sourceDatasetId: this.dataset.id + 1

                        });
                        this.server.completeFetchFor(this.view.imports, [this.lastImport]);
                    });

                    it("has an 'imported xx ago' description", function() {
                        var sourceTable = this.lastImport.source();
                        expect(this.view.$(".last_import")).toContainTranslation("import.last_imported_into", {timeAgo: chorus.helpers.relativeTimestamp(this.lastImport.get('completedStamp')), tableLink: "sourcey"});
                        expect(this.view.$(".last_import a")).toHaveHref(sourceTable.showUrl())
                    });

                    it("doesn't display a 'import now' link", function() {
                        expect(this.view.$(".import_now")).not.toExist();
                    });
                });

                context("and the dataset has received an import from a file", function() {
                    beforeEach(function() {
                        this.csvImport = rspecFixtures.csvImportSet().first();
                        this.csvImport.set({
                            startedStamp: "2012-02-29T13:35:38Z",
                            completedStamp: "2012-02-29T14:35:38Z",
                            success: true,
                            fileName: "some_source_file.csv"
                        });
                        this.server.completeFetchFor(this.dataset.getImports(), [this.csvImport]);
                    });

                    it("has an 'imported xx ago' description", function() {
                        expect(this.view.$(".last_import")).toContainTranslation("import.last_imported_into", {
                            timeAgo: chorus.helpers.relativeTimestamp("2012-02-29T14:35:38Z"),
                            tableLink: "some_source_..."
                        });
                    });

                    it("renders the filename as a span with a title", function() {
                        expect(this.view.$(".last_import a")).not.toExist();
                        expect(this.view.$(".last_import .source_file")).toBe("span");
                        expect(this.view.$(".last_import .source_file")).toHaveText("some_source_...");
                        expect(this.view.$(".last_import .source_file")).toHaveAttr("title", "some_source_file.csv")
                    });

                    it("doesn't display a 'import now' link", function() {
                        expect(this.view.$(".import_now")).not.toExist();
                    });
                });
            });

            context("when the dataset can be the source of an import", function() {
                beforeEach(function() {
                    chorus.PageEvents.broadcast("dataset:selected", this.dataset);
                });

                itShowsTheAppropriateDeleteLink(true, "table");
                itDoesNotHaveACreateDatabaseViewLink();

                it("fetches the imports and import schedules for the dataset", function() {
                    expect(this.dataset.getImports()).toHaveBeenFetched();
                    expect(this.dataset.getImportSchedules()).toHaveBeenFetched();
                });

                context("when the dataset has no import information", function() {
                        beforeEach(function() {
                            this.server.completeFetchFor(this.view.resource.getImports(), []);
                            this.server.completeFetchFor(this.view.resource.getImportSchedules(), []);
                        });

                        context("and the current user has update permissions on the workspace", function() {
                            beforeEach(function() {
                                this.view.resource._workspace = rspecFixtures.workspace({ id: 6008, permission: ["update"] });
                                this.view.render();
                            });

                            context("and the workspace has a sandbox", function() {
                                it("shows the 'import now' link", function() {
                                    expect(this.view.$("a.import_now")).toExist();
                                });

                                it("has a 'create import schedule' link", function() {
                                    var createScheduleLink = this.view.$("a.create_schedule");
                                    expect(createScheduleLink.text()).toMatchTranslation("actions.create_schedule");
                                });

                                it("should have the dataset attached as data-dataset", function() {
                                    expect(this.view.$("a.create_schedule[data-dialog=ImportScheduler]").data("dataset")).toBe(this.dataset);
                                });

                                it("should have the workspace attached as data-workspace", function() {
                                    expect(this.view.$("a.create_schedule[data-dialog=ImportScheduler]").data("workspace")).toBe(this.view.resource.workspace());
                                });
                            });

                            context("and the workspace does not have a sandbox", function() {
                                beforeEach(function() {
                                    delete this.view.resource.workspace()._sandbox;
                                    this.view.resource.workspace().set({
                                        "sandboxInfo": null
                                    });
                                    this.view.render();
                                });

                                it("disables the 'import now' link", function() {
                                    expect(this.view.$("a.import_now")).not.toExist();
                                    expect(this.view.$("span.import_now")).toHaveClass('disabled');
                                });

                                it("disables 'create import schedule' link", function() {
                                    expect(this.view.$("a.create_schedule")).not.toExist();
                                    expect(this.view.$("span.create_schedule")).toHaveClass('disabled');
                                });
                            });
                        });

                        context("and the current user does not have update permissions on the workspace", function() {
                            beforeEach(function() {
                                this.view.resource._workspace = rspecFixtures.workspace({ id: 6009, permission: ["read"] })
                                this.view.render();
                            });

                            it("does not have a 'create import schedule' link", function() {
                                expect(this.view.$("a.create_schedule")).not.toExist();
                            });

                            it("does not have an 'import now' link", function() {
                                expect(this.view.$("a.import_now.dialog")).not.toExist();
                            });
                        });

                        it("doesn't have an 'edit import schedule' link'", function() {
                            expect(this.view.$("a.edit_schedule")).not.toExist();
                        });
                    });

                context("when the dataset has an import schedule", function() {
                    beforeEach(function() {
                        var importSchedules = rspecFixtures.datasetImportScheduleSet();

                        this.importSchedule = importSchedules.last();
                        this.importSchedule.set({
                            endDate: "2013-06-02T00:00:00Z",
                            frequency: "weekly",
                            toTable: "our_destination",
                            startDatetime: "2012-02-29T14:23:58Z",
                            nextImportAt: Date.formatForApi(Date.today().add(1).year())
                        });
                        this.view.resource._workspace = rspecFixtures.workspace({ id: 6010, permission: ["update"] })
                        this.server.completeFetchFor(this.dataset.getImportSchedules(), importSchedules.models);
                    });

                    it("shows the next import time", function() {
                        expect(this.view.$(".next_import").text()).toContainTranslation("import.next_import", {
                            nextTime: "in 1 year",
                            tableRef: "our_destinat..."
                        });
                    });
                    itHasActionLinks(["import_now", "edit_schedule"]);
                });

                context("when the dataset has a last import", function() {
                    beforeEach(function() {
                        this.imports = rspecFixtures.datasetImportSet();
                        this.lastImport = this.imports.last();
                        this.lastImport.set({
                            startedStamp: "2012-02-29T14:23:58Z",
                            completedStamp: "2012-02-29T14:23:59Z",
                            success: true,
                            toTable: 'our_destination',
                            destinationDatasetId: 12345,
                            sourceDatasetId: this.dataset.id
                        });
                        this.server.completeFetchFor(this.view.imports, [this.lastImport]);
                        this.server.completeFetchFor(this.view.importSchedules, []);
                    });

                    itHasActionLinks(["import_now", "create_schedule"]);

                    it("has an 'imported xx ago' description", function() {
                        var lastImport = this.view.imports.last();
                        var destTable = lastImport.destination();
                        expect(this.view.$(".last_import")).toContainTranslation("import.last_imported", {timeAgo: chorus.helpers.relativeTimestamp(lastImport.get('completedStamp')), tableLink: "our_destinat..."})
                        expect(this.view.$(".last_import a")).toHaveHref(destTable.showUrl())
                    });
                });

            });
            function itHasActionLinks(linkClasses) {
                var possibleLinkClasses = ["import_now", "edit_schedule", "create_schedule"];

                context("when the user has permission to update in the workspace", function() {
                    beforeEach(function() {
                        this.view.resource._workspace = rspecFixtures.workspace({ id: 6002, permission: ["update"] })
                        this.view.render();
                    });

                    _.each(linkClasses, function(linkClass) {
                        it("has a '" + linkClass + "' link, which opens the import scheduler dialog", function() {
                            var link = this.view.$("a." + linkClass)
                            expect(link).toExist();
                            expect(link.text()).toMatchTranslation("actions." + linkClass);
                            var dialog = linkClass == "import_now" ? "ImportNow" : "ImportScheduler"
                            expect(link.data("dialog")).toBe(dialog);
                        });

                        it("attaches the dataset to the '" + linkClass + "' link", function() {
                            var link = this.view.$("a." + linkClass)
                            expect(link.data("dataset")).toBe(this.dataset);
                        });
                    });

                    _.each(_.difference(possibleLinkClasses, linkClasses), function(linkClass) {
                        it("does not have a '" + linkClass + "' link", function() {
                            expect(this.view.$("a." + linkClass)).not.toExist();
                        });
                    });
                });

                context("when the user does not have permission to update things in the workspace", function() {
                    beforeEach(function() {
                        this.view.resource._workspace = rspecFixtures.workspace({ id: 6003, permission: ["read"] })
                        this.view.render();
                    });

                    _.each(possibleLinkClasses, function(linkClass) {
                        it("does not have a '" + linkClass + "' link", function() {
                            expect(this.view.$("a." + linkClass)).not.toExist();
                        });
                    });
                });
            }

            context("when the dataset is a source view", function() {
                beforeEach(function() {
                    this.dataset = rspecFixtures.workspaceDataset.sourceView();
                    chorus.PageEvents.broadcast("dataset:selected", this.dataset);
                });

                itDoesNotShowTheDuplicateChorusViewLink();
                itShowsTheAppropriateDeleteLink(true, "view");
                itDoesNotHaveACreateDatabaseViewLink();
            });

            context("when the dataset is a chorus view", function() {
                beforeEach(function() {
                    this.dataset = newFixtures.workspaceDataset.chorusView({ objectName: "annes_table", query: "select * from foos;" });
                    chorus.PageEvents.broadcast("dataset:selected", this.dataset);
                });

                itShowsTheAppropriateDeleteLink(true, "chorus view");

                it("shows the 'duplicate' link'", function() {
                    expect(this.view.$("a.duplicate").text()).toMatchTranslation("dataset.chorusview.duplicate");
                });

                describe("clicking the 'duplicate' link", function() {
                    beforeEach(function() {
                        this.modalSpy.reset();
                        this.view.$("a.duplicate").click();
                    });

                    it("launches the name chorus view dialog", function() {
                        expect(this.modalSpy).toHaveModal(chorus.dialogs.VerifyChorusView);
                    });

                    it("passes the dialog a duplicate of the chorus view", function() {
                        expect(this.modalSpy.lastModal().model.attributes).toEqual(this.dataset.createDuplicateChorusView().attributes);
                    });
                });

                it("shows the 'Create as a database view' link", function() {
                    expect(this.view.$("a.create_database_view[data-dialog=CreateDatabaseView]")).toContainTranslation("actions.create_database_view");
                });
            });

            context("when the dataset is a source table", function() {
                _.each(["TABLE", "EXTERNAL_TABLE", "MASTER_TABLE", "HDFS_EXTERNAL_TABLE"], function(type) {
                    beforeEach(function() {
                        this.dataset = rspecFixtures.workspaceDataset.sourceTable({ objectType : type});
                        chorus.PageEvents.broadcast("dataset:selected", this.dataset);
                    });

                    itShowsTheAppropriateDeleteLink(true, type);
                    itDoesNotHaveACreateDatabaseViewLink();
                    itDoesNotShowTheDuplicateChorusViewLink();
                })
            })

            it("has an associate with another workspace link", function() {
                expect(this.view.$('.actions .associate')).toContainTranslation("actions.associate_with_another_workspace");
                this.view.$('.actions .associate').click();
                expect(this.modalSpy).toHaveModal(chorus.dialogs.AssociateWithWorkspace);
            });

            it("has the 'add a note' link with the correct data", function() {
                var notesNew = this.view.$("a.dialog[data-dialog=NotesNew]");

                expect(notesNew).toHaveData("entityId", this.dataset.id);
                expect(notesNew).toHaveData("entityType", "dataset");
                expect(notesNew).toHaveData("displayEntityType", this.dataset.metaType());
                expect(notesNew).toHaveData("allowWorkspaceAttachments", true);
            });

            function itDoesNotHaveACreateDatabaseViewLink() {
                it("does not have a create database view link", function() {
                    expect(this.view.$("a.create_database_view")).not.toExist();
                });
            }

            function itShowsTheAppropriateDeleteLink(shouldBePresent, type) {
                if (shouldBePresent) {
                    var keyPrefix, textKey;

                    if (type == "chorus view") {
                        keyPrefix = "delete";
                        textKey = "actions.delete";
                    } else if (type == "view") {
                        keyPrefix = "disassociate_view";
                        textKey = "actions.delete_association";
                    } else {
                        keyPrefix = "disassociate_table";
                        textKey = "actions.delete_association";
                    }

                    context("and the logged-in user has update permission on the workspace", function() {
                        beforeEach(function() {
                            this.view.resource._workspace = rspecFixtures.workspace({ id: 6004, permission: ["update"] });
                            this.view.render();
                        });

                        it("displays a delete link", function() {
                            var el = this.view.$("a.alert[data-alert=DatasetDelete][data-key-prefix=" + keyPrefix + "]");
                            expect(el).toExist();
                            expect(el).toHaveText(t(textKey));
                        });
                    });

                    context("and the logged-in user does not have update permission on the workspace", function() {
                        beforeEach(function() {
                            this.view.resource._workspace = rspecFixtures.workspace({ id: 6005, permission: ["read"] });
                            this.view.render();
                        });

                        it("does not display a delete link", function() {
                            expect(this.view.$("a.alert[data-alert=DatasetDelete]")).not.toExist();
                        });
                    });
                } else {
                    it("does not display a delete link", function() {
                        this.view.render();
                        expect(this.view.$("a.alert[data-alert=DatasetDelete]")).not.toExist();
                    });
                }
            }

            function itDoesNotShowTheDuplicateChorusViewLink() {
                it("does not show the 'duplicate' link", function() {
                    expect(this.view.$("a.duplicate")).not.toExist();
                });
            }
        });

        context("when there is not a workspace", function() {
            beforeEach(function() {
                this.dataset = rspecFixtures.dataset({id: "XYZ"});
                chorus.PageEvents.broadcast("dataset:selected", this.dataset);
            });

            it("has the 'add a note' link with the correct data", function() {
                var notesNew = this.view.$("a.dialog[data-dialog=NotesNew]");

                expect(notesNew).toHaveData("entityId", this.dataset.id);
                expect(notesNew).toHaveData("entityType", "dataset");
                expect(notesNew).toHaveData("displayEntityType", this.dataset.metaType());
                expect(notesNew).not.toHaveData("allowWorkspaceAttachments", true);
            });

            it("does not have the 'Import Now' action", function() {
                expect(this.view.$(".actions .import_now")).not.toExist();
            });

            it("does not display a delete link", function() {
                spyOn(this.view.resource, 'isDeleteable').andReturn(true);
                this.view.render();
                expect(this.view.$("a.alert[data-alert=DatasetDelete]")).not.toExist();
            });

            it("has a link to associate the dataset with a workspace", function() {
                expect(this.view.$('.actions .associate')).toContainTranslation('actions.associate_with_workspace');
            });

            describe("when the 'associate with workspace' link is clicked", function() {
                beforeEach(function() {
                    this.view.$("a.associate").click();
                });

                it("displays the associate with workspace dialog", function() {
                    expect(chorus.modal).toBeA(chorus.dialogs.AssociateWithWorkspace);
                });

                it("lists only active workspaces", function() {
                    expect(chorus.modal.options.activeOnly).toBeTruthy();
                });

                describe("when the dialog successfully associates", function() {
                    beforeEach(function() {
                        this.server.reset();
                        chorus.PageEvents.broadcast("workspace:associated");
                    });

                    it("re-fetches the resource", function() {
                        expect(this.view.resource).toHaveBeenFetched();
                    });
                });
            });
        });
    });

    describe("when a single dataset is checked", function() {
        beforeEach(function() {
            this.checkedDatasets = new chorus.collections.DynamicDatasetSet([
                rspecFixtures.workspaceDataset.datasetTable()
            ]);

            this.multiSelectSection = this.view.$(".multiple_selection");
            chorus.PageEvents.broadcast("dataset:checked", this.checkedDatasets);
        });

        it("does not display the multiple selection section", function() {
            expect(this.multiSelectSection).toHaveClass("hidden");
        });

        context("when two datasets are checked", function() {
            beforeEach(function() {
                this.checkedDatasets.add(rspecFixtures.workspaceDataset.datasetTable());
                chorus.PageEvents.broadcast("dataset:checked", this.checkedDatasets);
            });

            it("does display the multiple selection section", function() {
                expect(this.multiSelectSection).not.toHaveClass("hidden");
            });

            it("displays the number of selected datasets", function() {
                expect(this.multiSelectSection.find(".count").text()).toMatchTranslation("dataset.sidebar.multiple_selection.count", {count: 2});
            });

            it("displays the 'associate with workspace' link", function() {
                expect(this.multiSelectSection.find("a.associate")).toContainTranslation("actions.associate_with_another_workspace");
            });

            describe("clicking the 'associate with workspace' link", function() {
                beforeEach(function() {
                    this.multiSelectSection.find("a.associate").click();
                });

                it("launches the dialog for associating multiple datasets with a workspace", function() {
                    var dialog = this.modalSpy.lastModal();
                    expect(dialog).toBeA(chorus.dialogs.AssociateMultipleWithWorkspace);
                    expect(dialog.datasets).toBe(this.checkedDatasets);
                });
            });

            context("when a dataset is selected", function() {
                beforeEach(function() {
                    chorus.PageEvents.broadcast("dataset:selected", rspecFixtures.workspaceDataset.datasetTable());
                });

                it("should still show the multiple selection section", function() {
                    expect(this.view.$(".multiple_selection")).not.toHaveClass("hidden");
                });

                it("should retain the selection count when the view is re-rendered", function() {
                    expect(this.view.$(".multiple_selection .count").text()).toMatchTranslation("dataset.sidebar.multiple_selection.count", {count: 2});
                });
            });
        });
    });

    describe("column statistics", function() {
        beforeEach(function() {
            this.dataset = rspecFixtures.workspaceDataset.datasetTable();
            this.column = rspecFixtures.databaseColumnSet([{},{
                dataType: "int8",
                typeCategory: "WHOLE_NUMBER",
                statistics: {
                    commonValues: [46, 38],
                    distinctValue: 998710,
                    max: "1199961.0",
                    min: "200075.0",
                    nullFraction: 0.103678
                }
            }]).at(1);

            chorus.PageEvents.broadcast("dataset:selected", this.dataset);
            this.view.resource.statistics().set({lastAnalyzedTime: "2012-01-24T12:25:11Z"});
            chorus.PageEvents.broadcast("column:selected", this.column);
            this.view.render();
        });

        describe("statistics labels", function() {
            it("should display the column name", function() {
                expect(this.view.$(".column_title .title").text()).toContainTranslation("dataset.column_name");
                expect(this.view.$(".column_title .column_name").text()).toBe(this.column.get("name"));
            });

            it("should display the column labels in the correct order", function() {
                expect(this.view.$(".column_statistics .pair").eq(0).find(".key")).toContainTranslation("dataset.column_statistics.type_category");
                expect(this.view.$(".column_statistics .pair").eq(1).find(".key")).toContainTranslation("dataset.column_statistics.type");
                expect(this.view.$(".column_statistics .pair").eq(2).find(".key")).toContainTranslation("dataset.column_statistics.min");
                expect(this.view.$(".column_statistics .pair").eq(3).find(".key")).toContainTranslation("dataset.column_statistics.max");
                expect(this.view.$(".column_statistics .pair").eq(4).find(".key")).toContainTranslation("dataset.column_statistics.distinct");
                expect(this.view.$(".column_statistics .pair").eq(5).find(".key")).toContainTranslation("dataset.column_statistics.pctnull");
                expect(this.view.$(".column.description").find("h4")).toContainTranslation("dataset.column_statistics.description");

                expect(this.view.$(".column_statistics .multiline").eq(0).find(".key")).toContainTranslation("dataset.column_statistics.common");
            });

            it("should display a comment for the column", function() {
                expect(this.view.$(".column.description p")).toContainText(this.column.get("description"));
            });
        });

        describe("statistics values", function() {
            context("when the dataset has never been analyzed", function() {
                beforeEach(function() {
                    this.view.resource.statistics().set({
                        lastAnalyzedTime: null
                    });
                    this.column.set({
                        typeCategory: "WHOLE_NUMBER",
                        dataType: "int8",
                        statistics: {
                            max: "1199961.0",
                            median: "725197.0",
                            min: "200075.0"
                        }
                    });
                    this.view.render();
                });

                it("should only display the typeCategory and type", function() {
                    expect(this.view.$(".column_statistics .pair").length).toBe(2);
                    expect(this.view.$(".column_statistics .type_category .value")).toExist();
                    expect(this.view.$(".column_statistics .type .value")).toExist();
                });
            });

            context("when statistics are available", function() {
                it("should display the statistics", function() {
                    expect(this.view.$(".column_statistics .type_category .value").text()).toBe(this.column.get("typeClass"));
                    expect(this.view.$(".column_statistics .type .value").text()).toBe("int8");
                    expect(this.view.$(".column_statistics .min .value").text()).toBe("200075");
                    expect(this.view.$(".column_statistics .max .value").text()).toBe("1199961");
                    expect(this.view.$(".column_statistics .distinct .value").text()).toBe("998710");
                    expect(this.view.$(".column_statistics .pctnull .value").text()).toBe("10.37%");

                    expect(this.view.$(".column_statistics .common .value").eq(0).text()).toBe("46");
                    expect(this.view.$(".column_statistics .common .value").eq(1).text()).toBe("38");
                });
            });

            context("when the min is not available", function() {
                it("should not display the min", function() {
                    this.column.set({statistics: {min: null}});
                    this.view.render();
                    expect(this.view.$(".column_statistics .min")).not.toExist();
                });
            });

            context("when the median is not available", function() {
                it("should not display the median", function() {
                    this.column.set({statistics: {median: null}});
                    this.view.render();
                    expect(this.view.$(".column_statistics .median")).not.toExist();
                });
            });

            context("when the avg is not available", function() {
                it("should not display the avg", function() {
                    this.column.set({statistics: {avg: null}});
                    this.view.render();
                    expect(this.view.$(".column_statistics .avg")).not.toExist();
                });
            });

            context("when the max is not available", function() {
                it("should not display the max", function() {
                    this.column.set({statistics: {max: null}});
                    this.view.render();
                    expect(this.view.$(".column_statistics .max")).not.toExist();
                });
            });

            context("when the stdDeviation is not available", function() {
                it("should not display the stdDeviation", function() {
                    this.column.set({statistics: {stdDeviation: null}});
                    this.view.render();
                    expect(this.view.$(".column_statistics .stdDeviation")).not.toExist();
                });
            });

            context("when the distinctValue is not available", function() {
                it("should not display the distinctValue", function() {
                    this.column.set({statistics: {distinctValue: null}});
                    this.view.render();
                    expect(this.view.$(".column_statistics .distinctValue")).not.toExist();
                });
            });

            context("when the commonValues is not available", function() {
                it("should not display the commonValues", function() {
                    this.column.set({statistics: {commonValues: []}});
                    this.view.render();
                    expect(this.view.$(".column_statistics .commonValues")).not.toExist();
                });
            });

            context("when the nullFraction is not available", function() {
                it("should not display the nullFraction", function() {
                    this.column.set({statistics: {nullFraction: null}});
                    this.view.render();
                    expect(this.view.$(".column_statistics .nullFraction")).not.toExist();
                });
            });
        });
    });

    describe("when importSchedule:changed is triggered", function() {
        beforeEach(function() {
            this.view.resource = rspecFixtures.workspaceDataset.datasetTable();
            this.newImportSchedule = rspecFixtures.datasetImportScheduleSet().at(0);
            spyOn(this.view, 'render').andCallThrough();
            chorus.PageEvents.broadcast("importSchedule:changed", this.newImportSchedule);
        });

        it("updates the importConfiguration and renders", function() {
            expect(this.view.resource.importSchedule()).toBe(this.newImportSchedule);
            expect(this.view.render).toHaveBeenCalled();
        });
    });

    describe("has all the translations for all objectTypes", function() {
        _.each(["CHORUS_VIEW", "VIEW", "TABLE", "TABLE", "HDFS_EXTERNAL_TABLE", "EXTERNAL_TABLE"], function(type) {
            it("does not have any missing translations for" + type, function() {
                this.dataset = rspecFixtures.workspaceDataset.datasetTable({objectType: type});
                chorus.PageEvents.broadcast("dataset:selected", this.dataset);
                expect(this.view.tabs.activity.options.type).not.toContain("missing");
            })
        }, this)
    });

    describe("event handing", function() {
        describe("start:visualization", function() {
            beforeEach(function() {
                expect($(this.view.el)).not.toHaveClass("visualizing");
                chorus.PageEvents.broadcast("start:visualization");
            });

            it("adds the 'visualizing' class to sidebar_content", function() {
                expect($(this.view.el)).toHaveClass("visualizing");
            });
        });
        describe("cancel:visualization", function() {
            beforeEach(function() {
                chorus.PageEvents.broadcast("start:visualization")
                expect($(this.view.el)).toHaveClass("visualizing")
                chorus.PageEvents.broadcast("cancel:visualization")
            });

            it("removes the 'visualizing' class from sidebar_content", function() {
                expect($(this.view.el)).not.toHaveClass("visualizing")
            });
        });
    });
});
