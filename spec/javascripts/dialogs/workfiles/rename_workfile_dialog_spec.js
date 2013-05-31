describe("chorus.dialogs.RenameWorkfile", function() {
    beforeEach(function() {
        this.workfile = rspecFixtures.workfile.sql({fileName: "originalName.sql"});
        this.dialog = new chorus.dialogs.RenameWorkfile({model: this.workfile});
        this.dialog.render();
    });

    it("should have content that says to change file name", function(){
        expect(this.dialog.title).toMatchTranslation("workfile.rename_dialog.title");
    });

    it("should have an input field containing the current file name", function(){
       expect(this.dialog.$('input').val()).toBe("originalName.sql");
    });

    it("should update the workfile when clicking submit", function() {
        this.dialog.$('input').val("newName.sql").change();
        this.dialog.$("button.submit").click();
        expect(this.workfile.get("fileName")).toBe("newName.sql");
        expect(this.workfile).toHaveBeenUpdated();
    });
});