describe("chorus.dialogs.EditProjectStatus", function() {
    beforeEach(function() {
        this.workspace = backboneFixtures.workspace();
        this.workspace.set('projectStatus', 'at_risk');
        this.dialog = new chorus.dialogs.EditProjectStatus({ model: this.workspace });
    });

    describe("render", function() {
        beforeEach(function() {
            this.dialog.render();
        });

        it("selects the appropriate project status option from the model", function () {
            expect(this.dialog.$("select[name='projectStatus']").val()).toEqual('at_risk');
        });

        context("submitting the form with valid data", function() {
            beforeEach(function() {
                spyOnEvent($(document), "close.facebox");
                spyOn(this.dialog.model, "save").andCallThrough();
                this.dialog.$("select[name='projectStatus']").val('needs_attention');
                this.dialog.$('.submit').click();
            });

            it("saves the workspace", function() {
                expect(this.dialog.model.save).toHaveBeenCalled();
            });

            it("updates the project status", function() {
                expect(this.server.lastUpdateFor(this.dialog.model).params()['workspace[project_status]']).toEqual('needs_attention');
            });
        });
    });
});
