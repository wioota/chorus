describe("chorus.dialogs.ChangeWorkfileSchemaDialog", function() {
    beforeEach(function() {
        this.model = rspecFixtures.workfile.sql();
        this.dialog = new chorus.dialogs.ChangeWorkfileSchema({ model: this.model });
    });

    describe("#render", function () {
        beforeEach(function () {
            this.dialog.render();
        });
        it("has the right title", function () {
            expect(this.dialog.$(".dialog_header h1")).toContainTranslation("workfile.change_workfile_schema.title");
        });

        it("has the right label text", function(){
            expect(this.dialog.$el).toContainTranslation("workfile.change_workfile_schema.select_schema");
        });

        it("has a Save Search Path button", function () {
            expect(this.dialog.$("button.submit").text().trim()).toMatchTranslation("workfile.change_workfile_schema.save_search_path");
        });

        it("has a Cancel button", function () {
            expect(this.dialog.$("button.cancel").text().trim()).toMatchTranslation("actions.cancel");
        });
    });

    describe("saving", function() {
        beforeEach(function() {
            spyOn(this.model, "saveWorkfileAttributes").andCallThrough();
            spyOn(this.dialog, "closeModal");
            this.dialog.render();
            this.dialog.$("button.submit").click();
        });

        it("puts the button in 'loading' mode", function() {
            expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
            expect(this.dialog.$("button.submit")).toContainTranslation("actions.saving");
        });

        it("saves the model", function(){
            expect(this.model.saveWorkfileAttributes).toHaveBeenCalled();
        });

        context("when save succeeds", function(){
            beforeEach(function() {
                spyOn(chorus, "toast");
                this.dialog.model.trigger("saved");
            });

            it("dismisses the dialog", function(){
                expect(this.dialog.closeModal).toHaveBeenCalled();
            });

            it("displays toast message", function() {
                expect(chorus.toast).toHaveBeenCalledWith("workfile.change_workfile_schema.saved_message");
            });
        });

        context('when the save fails', function(){
            beforeEach(function() {
                spyOn(this.dialog, "showErrors");
                this.server.lastUpdateFor(this.model).failForbidden({message: "Forbidden"});
            });

            it("shows an error message", function() {
                expect(this.dialog.showErrors).toHaveBeenCalledWith(this.model);
            });

            it("doesn't close the dialog box", function () {
                this.dialog.model.trigger("savedFailed");
                expect(this.dialog.closeModal).not.toHaveBeenCalled();
            });
        });
    });
});