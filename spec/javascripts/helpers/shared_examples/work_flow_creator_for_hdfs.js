jasmine.sharedExamples.WorkFlowCreatorForHdfs = function() {
    context("when work flows are enabled and the hdfs data source supports work flows", function() {
        beforeEach(function() {
            this.view.options.hdfsDataSource = backboneFixtures.hdfsDataSource({supportsWorkFlows: true});
            chorus.models.Config.instance().set('workflowConfigured', true);
            this.modalSpy = this.modalSpy || stubModals();
            this.view.render();
        });

        it("has a new work flow link", function() {
            expect(this.view.$("a.new_work_flow")).toContainTranslation("sidebar.new_work_flow");
        });

        itBehavesLike.aDialogLauncher("a.new_work_flow", chorus.dialogs.HdfsWorkFlowWorkspacePicker);
    });

    context("when work flows are enabled but the hdfs data source does not support work flows", function() {
        beforeEach(function() {
            this.view.options.hdfsDataSource = backboneFixtures.hdfsDataSource({supportsWorkFlows: false});
            chorus.models.Config.instance().set('workflowConfigured', true);
            this.view.render();
        });

        it("does note have a new work flow link", function() {
            expect(this.view.$("a.new_work_flow")).not.toExist();
        });
    });

    context("when work flows are not enabled", function() {
        beforeEach(function() {
            chorus.models.Config.instance().set('workflowConfigured', false);
            this.view.render();
        });

        it("does note have a new work flow link", function() {
            expect(this.view.$("a.new_work_flow")).not.toExist();
        });
    });
};