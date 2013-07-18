describe("chorus.views.HdfsShowFileSidebar", function() {
    beforeEach(function() {
        spyOn(chorus.views.ImportDataGrid.prototype, 'initializeDataGrid');

        var yesterday = new Date().addDays(-1).toString("yyyy-MM-ddTHH:mm:ssZ");

        this.hdfsEntry = backboneFixtures.hdfsFile({id: 8675309, lastUpdatedStamp: yesterday});
        this.hdfsDataSource = backboneFixtures.hdfsDataSource({supportsWorkFlows: true});
        this.view = new chorus.views.HdfsShowFileSidebar({ model: this.hdfsEntry, hdfsDataSource: this.hdfsDataSource});
    });

    describe("#setup", function() {
        it("fetches the ActivitySet for the hdfs file", function() {
            expect(this.hdfsEntry.activities()).toHaveBeenFetched();
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.modalSpy = stubModals();
            this.view.render();
        });

        it("has the right title (the filename)", function() {
            expect(this.view.$(".file_name")).toContainText(this.hdfsEntry.get('name'));
        });

        it("shows the correct last_updated value", function() {
            expect(this.view.$(".last_updated")).toContainTranslation("hdfs.last_updated", { when: "1 day ago" });
        });

        it("shows the 'add a note' link", function() {
            expect(this.view.$("a.add_note")).toContainTranslation("actions.add_note");
        });

        itBehavesLike.aDialogLauncher("a.add_note", chorus.dialogs.NotesNew);

        it("has an activity list", function() {
            expect(this.view.$(".activity_list")).toExist()
;        });

        it("should have an activities tab", function() {
            expect(this.view.$('.tabbed_area .activity_list')).toExist();
        });

        it("should have an external table link", function() {
            expect(this.view.$("a.external_table")).toExist();
        });

        itBehavesLike.aDialogLauncher("a.external_table", chorus.dialogs.CreateExternalTableFromHdfs);

        it("should re-render when csv_import:started is triggered", function() {
            this.server.reset();
            chorus.PageEvents.trigger("csv_import:started");
            expect(this.hdfsEntry.activities()).toHaveBeenFetched();
        });

        context("when the hdfs file is non-binary and has no server errors", function() {
            beforeEach(function() {
                this.hdfsEntry.set("isBinary", false);
                this.view.render();
            });

            it("has a link to create external table", function() {
                expect(this.view.$("a.external_table")).toExist();
            });
        });

        context("when the hdfs file is binary", function() {
            beforeEach(function() {
                this.hdfsEntry.set("isBinary", true);
                this.view.render();
            });

            it("does not have a link to create external table", function() {
                expect(this.view.$("a.external_table")).not.toExist();
            });
        });

        context("when the hdfs file has server errors", function() {
            beforeEach(function() {
                this.hdfsEntry.serverErrors= {record: "HDFS_SOMETHING_VERY_BAD"};
                this.view.render();
            });

            it("does not have a link to create external table", function() {
                expect(this.view.$("a.external_table")).not.toExist();
            });
        });

        context("when the hdfs file has not loaded", function() {
            beforeEach(function() {
                this.hdfsEntry.loaded = false;
                this.view.render();
            });

            it("does not have a link to create external table", function() {
                expect(this.view.$("a.external_table")).not.toExist();
            });
        });
    });

    describe("when the activity list collection is changed", function() {
        beforeEach(function() {
            spyOn(this.view, "postRender"); // check for #postRender because #render is bound
            this.view.tabs.activity.collection.trigger("changed");
        });

        it("re-renders", function() {
            expect(this.view.postRender).toHaveBeenCalled();
        });
    });
});
