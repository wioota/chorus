describe("chorus.dialogs.RenameWorkfile", function() {
    context("when the workfile is sql", function() {
        beforeEach(function(){
            this.workfile = rspecFixtures.workfile.sql({fileName: "originalName.sql"});
            this.dialog = new chorus.dialogs.RenameWorkfile({model: this.workfile});
            this.dialog.render();
        });

        it("should have an input field containing the current file name", function(){
            expect(this.dialog.$('input').val()).toBe("originalName");
        });

        it("should display a different version of the dialog", function() {
            expect(this.dialog.additionalContext().isSql).toBeTruthy();
        });

        context("submitting the form", function() {
            beforeEach(function(){
                this.dialog.$('input').val("newName").change();
                this.dialog.$("form").submit();
            });

            it ("should append .sql to the fileName", function() {
                expect(this.workfile.get("fileName")).toBe("newName.sql");
                expect(this.workfile).toHaveBeenUpdated();
            });
        });
    });

    beforeEach(function() {
        this.workfile = rspecFixtures.workfile.image({fileName: "originalName"});
        this.dialog = new chorus.dialogs.RenameWorkfile({model: this.workfile});
        this.dialog.render();
    });

    it("should have content that says to change file name", function(){
        expect(this.dialog.title).toMatchTranslation("workfile.rename_dialog.title");
    });

    it("should have an input field containing the current file name", function(){
       expect(this.dialog.$('input').val()).toBe("originalName");
    });

    context("with invalid form values", function() {
        beforeEach(function() {
            this.dialog.$('input').val("").keyup();
        });

        it("does not let you submit the form", function() {
            expect(this.dialog.$("button.submit")).toBeDisabled();
        });
    });

    context("when submitting the form", function() {
        beforeEach(function() {
            spyOn(this.dialog, "closeModal");
            spyOnEvent(this.dialog.model, "change");
            this.dialog.$('input').val("newName.sql").change();
            this.dialog.$("form").submit();
        });

        it("should not change the fileName elsewhere until the save completes", function() {
            expect("change").not.toHaveBeenTriggeredOn(this.dialog.model);
        });

        it("should update the workfile", function() {
            expect(this.workfile.get("fileName")).toBe("newName.sql");
            expect(this.workfile).toHaveBeenUpdated();
        });

        it("should be loading", function() {
            expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
        });

        context("when the save is successful", function() {
            beforeEach(function() {
                this.server.lastUpdate().succeed();
            });

            it("closes the modal", function() {
                expect(this.dialog.closeModal).toHaveBeenCalled();
            });

            it("re-renders", function() {
                expect("change").toHaveBeenTriggeredOn(this.dialog.model);
            });
        });

        context("when the save fails", function() {
            beforeEach(function() {
                this.server.lastUpdate().failUnprocessableEntity();
            });

            it("stops the loading spinner", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
            });
        });
    });
});