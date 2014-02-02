describe("workfile work flow button", function () {
    beforeEach(function () {
        this.workspace = backboneFixtures.workspace();
        this.workspace.loaded = false;
        this.qtipElement = stubQtip();
    });

    context("when the user does not have permissions to create/edit workflows", function () {
        beforeEach(function () {
            this.view = new chorus.views.WorkfileIndexPageButtons({model: this.workspace});
            spyOn(this.workspace, 'currentUserCanCreateWorkFlows').andReturn(false);
            this.server.completeFetchFor(this.workspace);
        });

        it("does not show the create work flow button", function () {
            this.view.$("button.new_workfile").click();
            expect(this.qtipElement.find('.create_work_flow')).not.toExist();
        });
    });

    context("if the user has create/edit workflow permissions", function () {
        beforeEach(function () {
            this.view = new chorus.views.WorkfileIndexPageButtons({model: this.workspace});
            this.modalSpy = stubModals();
            spyOn(this.workspace, 'currentUserCanCreateWorkFlows').andReturn(true);
            this.server.completeFetchFor(this.workspace);
        });

        context("clicking the create workfile button", function () {
            beforeEach(function () {
                this.view.$("button.new_workfile").click();
            });

            context("clicking on 'Work Flow'", function () {
                it("launches the WorkFlowNew dialog", function () {
                    expect(this.modalSpy).not.toHaveModal(chorus.dialogs.WorkFlowNew);
                    expect(this.qtipElement.find('.create_work_flow')).toContainTranslation('work_flows.actions.create_work_flow');
                    this.qtipElement.find('.create_work_flow').click();
                    expect(this.modalSpy).toHaveModal(chorus.dialogs.WorkFlowNew);
                });
            });
        });
    });
});
