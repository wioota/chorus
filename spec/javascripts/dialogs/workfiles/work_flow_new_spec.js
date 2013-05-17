describe("chorus.dialogs.WorkFlowNew", function() {
    beforeEach(function() {
        this.workspace = rspecFixtures.workspace();
        this.dialog = new chorus.dialogs.WorkFlowNew();
        this.dialog.render();
    });

    it("has the right title", function() {
        expect(this.dialog.$(".dialog_header h1")).toContainTranslation("work_flows.new_dialog.title");
    });

    it("has an Add Work Flow button", function() {
        expect(this.dialog.$("button.submit")).toContainTranslation("work_flows.new_dialog.add_work_flow");
    });

    describe("submitting", function() {
        describe("with an invalid work flow name", function() {
            it("does not allow submitting", function() {
                this.dialog.$("input[name='fileName']").val("     ").keyup();
                expect(this.dialog.$("form button.submit")).toBeDisabled();
            });
        });

        describe("with valid form values", function() {
            it("submits the form", function() {
                this.dialog.$("input[name='fileName']").val("stuff").keyup();
                expect(this.dialog.$("form button.submit")).not.toBeDisabled();
            });
        });
    });
});