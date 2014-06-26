describe("chorus.views.HdfsEntryIndexPageButtons", function () {
    beforeEach(function () {
        this.entry = backboneFixtures.hdfsDir();
        this.entry.loaded = false;
        this.view = new chorus.views.HdfsEntryIndexPageButtons({model: this.entry});
    });

    context("before the entry is fetched", function () {
        beforeEach(function () {
            this.view.render();
        });

        it("does not render any buttons", function () {
            expect(this.view.$("button").length).toBe(0);
        });

    });

    context("after the entry is fetched", function () {
        beforeEach(function () {
            this.server.completeFetchFor(this.entry);
        });

        it("renders the add data button", function () {
            expect(this.view.$("button.add_data")).toExist();
            expect(this.view.$("button.add_data")).toContainTranslation("actions.add_data");
        });

        context("clicking the add data button", function () {
            beforeEach(function () {
                this.modalSpy = stubModals();
                this.view.$("button.add_data").click();
            });

            itBehavesLike.aDialogLauncher("button.add_data", chorus.dialogs.HdfsImportDialog);
        });
    });
});
