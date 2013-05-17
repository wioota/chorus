describe("workfile work flow button", function() {
    beforeEach(function() {
        this.workspace = rspecFixtures.workspace();
        this.workspace.loaded = false;
        this.view = new chorus.views.WorkfileIndexPageButtons({model: this.workspace});
        this.qtipElement = stubQtip();
    });

    context("after the workspace is fetched", function() {
        context("and the user can update the workspace", function() {
            beforeEach(function() {
                this.modalSpy = stubModals();
                spyOn(this.workspace, 'canUpdate').andReturn(true);
                this.server.completeFetchFor(this.workspace);
            });

            context("clicking the create workfile button", function() {
                beforeEach(function() {
                    this.view.$("button.new_workfile").click();
                });

                context("clicking on 'Work Flow'", function() {
                    it("launches the WorkFlowNew dialog", function() {
                        expect(this.modalSpy).not.toHaveModal(chorus.dialogs.WorkFlowNew);
                        expect(this.qtipElement.find('.create_work_flow')).toContainTranslation('work_flows.actions.create_work_flow');
                        this.qtipElement.find('.create_work_flow').click();
                        expect(this.modalSpy).toHaveModal(chorus.dialogs.WorkFlowNew);
                    });
                });
            });
        });
    });
});
