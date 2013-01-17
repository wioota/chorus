describe("chorus.dialogs.ChangeWorkfileSchemaDialog", function() {
    beforeEach(function() {
        this.dialog = new chorus.dialogs.ChangeWorkfileSchema();
    });

    describe("#render", function () {
        beforeEach(function () {
            this.dialog.render();
        });
        it("has the right title", function () {
            expect(this.dialog.$(".dialog_header h1")).toContainTranslation("workfile.change_workfile_schema.title");
        });
    });
});