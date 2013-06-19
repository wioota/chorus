describe("chorus.dialogs.WorkFlowNew", function() {
    beforeEach(function() {
        this.workspace = rspecFixtures.workspace();
        this.dialog = new chorus.dialogs.WorkFlowNew({workspace: this.workspace});
        this.dialog.render();
    });

    it("has the right title", function() {
        expect(this.dialog.$(".dialog_header h1")).toContainTranslation("work_flows.new_dialog.title");
    });

    it("has an Add Work Flow button", function() {
        expect(this.dialog.$("button.submit")).toContainTranslation("work_flows.new_dialog.add_work_flow");
    });

    it("shows some instructional text", function () {
       expect(this.dialog.$el).toContainTranslation("work_flows.new_dialog.info");
    });

    it("creates a location picker picker with the schema section hidden", function(){
       expect(this.dialog.$('.schema')).not.toExist();
    });

    context("when the workspace has a sandbox", function() {
        it("sets the default data source and database", function() {
            var sandboxDatabase = this.dialog.options.workspace.sandbox().database();
            expect(sandboxDatabase).toBeTruthy();
            expect(this.dialog.executionLocationPicker.getSelectedDatabase()).toEqual(sandboxDatabase);
        });
    });

    describe("submitting", function() {
        beforeEach(function() {
            // start with a valid form submission
            this.dialog.$("input[name='fileName']").val("stuff").keyup();

            this.fakeDatabase = rspecFixtures.database();
            spyOn(this.dialog.executionLocationPicker, "getSelectedDatabase").andReturn(this.fakeDatabase);
            this.dialog.executionLocationPicker.trigger('change');
        });

        describe("with valid form values", function() {
            it("enables the submit button", function() {
                expect(this.dialog.$("form button.submit")).not.toBeDisabled();
            });

            it("submits the form", function() {
                this.dialog.$("form").submit();
                expect(this.server.lastCreate().params()["workfile[entity_subtype]"]).toEqual('alpine');
                expect(this.server.lastCreate().params()["workfile[database_id]"]).toEqual(this.fakeDatabase.id);
            });
        });

        describe("when the workfile creation succeeds", function() {
            beforeEach(function() {
                spyOn(this.dialog, "closeModal");
                spyOn(chorus.router, "navigate");
                this.dialog.$("form").submit();
                this.server.completeSaveFor(this.dialog.resource, {id: 42});
            });

            it("closes the dialog", function() {
               expect(this.dialog.closeModal).toHaveBeenCalled();
            });

            it("navigates to the workflow page", function() {
               expect(chorus.router.navigate).toHaveBeenCalledWith("#/work_flows/42");
            });
        });

        describe("when the save fails", function() {
            beforeEach(function() {
                spyOn($.fn, 'stopLoading');
                this.dialog.$("form").submit();
                this.server.lastCreateFor(this.dialog.model).failUnprocessableEntity();
            });

            it("removes the spinner from the button", function() {
                expect($.fn.stopLoading).toHaveBeenCalledOnSelector("button.submit");
            });

            it("does not erase the fileName input", function() {
                expect(this.dialog.$("input[name='fileName']").val()).toBe("stuff");
            });
        });

        describe("when no database is selected", function() {
            it("disables the form", function() {
                spyOn(this.dialog.executionLocationPicker, "ready").andReturn(false);
                this.dialog.executionLocationPicker.trigger('change');

                expect(this.dialog.$("form button.submit")).toBeDisabled();
            });
        });

        describe("with an invalid work flow name", function() {
            it("does not allow submitting", function() {
                this.dialog.$("input[name='fileName']").val("     ").keyup();
                expect(this.dialog.$("form button.submit")).toBeDisabled();
            });
        });
    });
});