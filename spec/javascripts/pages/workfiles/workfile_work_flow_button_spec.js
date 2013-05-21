describe("workfile work flow button", function() {
    beforeEach(function() {
        this.workspace = rspecFixtures.workspace();
        this.workspace.loaded = false;
        this.qtipElement = stubQtip();
    });

    context("with workflows disabled", function() {
        beforeEach(function() {
            chorus.models.Config.instance().set("workFlowConfigured", false);
            this.view = new chorus.views.WorkfileIndexPageButtons({model: this.workspace});
            spyOn(this.workspace, 'canUpdate').andReturn(true);
            this.server.completeFetchFor(this.workspace);
        });

        it("does not show the create work flow button", function(){
            this.view.$("button.new_workfile").click();
            expect(this.qtipElement.find('.create_work_flow')).not.toExist();
        });
    });

    context("with workflows enabled", function() {
        beforeEach(function() {
            chorus.models.Config.instance().set("workFlowConfigured", true);
            this.view = new chorus.views.WorkfileIndexPageButtons({model: this.workspace});
            this.modalSpy = stubModals();
            spyOn(this.workspace, 'canUpdate').andReturn(true);
            this.server.completeFetchFor(this.workspace);
        });

            context("if the user can update the workspace", function() {

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

        it("does not apply the plugin multiple times", function(){
            var view1 = new chorus.views.WorkfileIndexPageButtons({model: this.workspace});
            var view2 = new chorus.views.WorkfileIndexPageButtons({model: this.workspace});
            this.view = new chorus.views.WorkfileIndexPageButtons({model: this.workspace});
            this.view.render();
            this.view.$("button.new_workfile").click();
            expect(this.qtipElement.find('.create_work_flow').length).toBe(1);
        });
    });
});
