describe("chorus.dialogs.ChangeWorkfileSchemaDialog", function() {
    beforeEach(function() {
        this.model = rspecFixtures.workfile.sql();
        this.dialog = new chorus.dialogs.ChangeWorkfileSchema({ model: this.model });
        this.dialog.render();
    });

    describe("#render", function () {
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

    describe("pre-populating the current schema", function() {
        beforeEach(function() {
            this.executionSchema = new chorus.models.Schema({id: 321});
            this.model = rspecFixtures.workfile.sql();
            this.model._executionSchema = this.executionSchema;
            this.dialog = new chorus.dialogs.ChangeWorkfileSchema({ model: this.model });
            this.dialog.render();
        });

        it("passes the current schema to the picker", function() {
            expect(this.dialog.schemaPicker.options.defaultSchema).toEqual(this.executionSchema);
        });
    });

    describe("saving", function() {
        beforeEach(function() {
            this.executionSchema = new chorus.models.Schema({id: 321});
            spyOn(this.model, "updateExecutionSchema").andCallThrough();
            spyOn(this.dialog.schemaPicker, "ready").andReturn(true);
            spyOn(this.dialog, "closeModal");
            spyOn(this.dialog.schemaPicker, "getSelectedSchema").andReturn(this.executionSchema);
            this.dialog.render();
            this.dialog.$("button.submit").click();
        });

        it("puts the button in 'loading' mode", function() {
            expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
            expect(this.dialog.$("button.submit")).toContainTranslation("actions.saving");
        });

        it("saves the model", function(){
            expect(this.model.updateExecutionSchema).toHaveBeenCalledWith(this.executionSchema);
        });

        context("when save succeeds", function(){
            beforeEach(function() {
                spyOn(chorus, "toast");
                this.workfileChangedSpy = jasmine.createSpy();
                chorus.PageEvents.subscribe("workfile:changed", this.workfileChangedSpy);
                this.dialog.model.trigger("saved");
                this.server.completeUpdateFor(this.model, _.extend(this.model.attributes, {executionSchema: this.executionSchema.attributes}));
            });

            it("dismisses the dialog", function(){
                expect(this.dialog.closeModal).toHaveBeenCalled();
            });

            it("displays toast message", function() {
                expect(chorus.toast).toHaveBeenCalledWith("workfile.change_workfile_schema.saved_message");
            });

            it("presents the new execution schema", function(){
                expect(this.model.executionSchema().get("id")).toEqual(this.executionSchema.get("id"));
            });

            it("updates the execution schema", function() {
                var lastUpdate = this.server.lastUpdateFor(this.model);
                var updatedExecutionSchemaId = URI.decode(lastUpdate.requestBody).match(/execution_schema\]\[id\]=(\d+)/)[1];
                expect(updatedExecutionSchemaId).toEqual("321");
            });

            it("broadcasts workfile:changed", function() {
                expect(this.workfileChangedSpy).toHaveBeenCalledWith(this.model);
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

            it("presents the original execution schema", function(){
                expect(this.model.executionSchema().get("id")).not.toEqual(this.executionSchema.get("id"));
            });
        });
    });

    context("when the schema picker is not ready", function () {
        beforeEach(function () {
            spyOn(this.dialog.schemaPicker, "ready").andReturn(false);
            this.dialog.schemaPicker.trigger("change");
        });

        it("disables the save schema button", function () {
            expect(this.dialog.$("button.submit")).toBeDisabled();
        });
    });

    context("when the schema picker is ready", function () {
        beforeEach(function () {
            spyOn(chorus.PageEvents, "broadcast").andCallThrough();
            spyOn(this.dialog.schemaPicker, "ready").andReturn(true);
            this.dialog.schemaPicker.trigger("change");
        });

        it("enables the save schema button", function () {
            expect(this.dialog.$("button.submit")).toBeEnabled();
        });
    });

    context("when the SchemaPicker triggers an error", function() {
        beforeEach(function() {
            var modelWithError = rspecFixtures.schemaSet();
            modelWithError.serverErrors = { fields: { a: { BLANK: {} } } };
            this.dialog.schemaPicker.trigger("error", modelWithError);
        });

        it("shows the error", function() {
            expect(this.dialog.$('.errors')).toContainText("A can't be blank");
        });

        context("and then the schemaPicker triggers clearErrors", function(){
            it("clears the errors", function() {
                this.dialog.schemaPicker.trigger("clearErrors");
                expect(this.dialog.$('.errors')).toBeEmpty();
            });
        });
    });
});