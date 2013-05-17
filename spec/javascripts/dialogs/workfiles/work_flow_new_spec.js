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

    it("creates a schema picker with the schema section hidden", function(){
       expect(this.dialog.schemaPicker.options.showSchemaSection).toBeFalsy();
    });

    context("when the workspace has a sandbox", function() {
        it("sets the default data source and database", function() {
            var database = this.dialog.model.sandbox().database();
            expect(database).toBeTruthy();
            expect(this.dialog.schemaPicker.selection.database).toEqual(database);
        });
    });

    describe("submitting", function() {
        beforeEach(function() {
            // start with a valid form submission
            this.dialog.$("input[name='fileName']").val("stuff").keyup();

            var fakeDatabase = rspecFixtures.database();
            spyOn(this.dialog.schemaPicker, "getSelectedDatabase").andReturn(fakeDatabase);
            this.dialog.schemaPicker.trigger('change');
        });

        describe("with valid form values", function() {
            it("submits the form", function() {
                expect(this.dialog.$("form button.submit")).not.toBeDisabled();
            });
        });

        describe("when no database is selected", function() {
            it("disables the form", function() {
                this.dialog.schemaPicker.getSelectedDatabase.andReturn(null);
                this.dialog.schemaPicker.trigger('change');

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