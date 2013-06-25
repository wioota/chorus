jasmine.sharedExamples.WorkFlowCreatorForHdfs = function() {
    context("when work flows are enabled and the hdfs data source supports work flows", function() {
        beforeEach(function() {
            this.view.options.hdfsDataSource = backboneFixtures.hdfsDataSource({supportsWorkFlows: true});
            chorus.models.Config.instance().set('workFlowConfigured', true);
            this.modalSpy = this.modalSpy || stubModals();
            this.view.render();
        });

        it("has a new work flow link", function() {
            expect(this.view.$("a.new_work_flow")).toContainTranslation("sidebar.new_work_flow");
        });

        context("when clicking the new work flow link", function() {
            beforeEach(function() {
                this.view.$("a.new_work_flow").click();
            });

            it("launches the dialog for creating a new work flow", function() {
                expect(this.modalSpy).toHaveModal(chorus.dialogs.HdfsWorkFlowWorkspacePicker);
                expect(this.modalSpy.lastModal().options.hdfsEntries.length).toBe(1);
                expect(this.modalSpy.lastModal().options.hdfsEntries).toContain(this.hdfsEntry);
            });
        });
    });

    context("when work flows are enabled but the hdfs data source does not support work flows", function() {
        beforeEach(function() {
            this.view.options.hdfsDataSource = backboneFixtures.hdfsDataSource({supportsWorkFlows: false});
            chorus.models.Config.instance().set('workFlowConfigured', true);
            this.view.render();
        });

        it("does note have a new work flow link", function() {
            expect(this.view.$("a.new_work_flow")).not.toExist();
        });
    });

    context("when work flows are not enabled", function() {
        beforeEach(function() {
            chorus.models.Config.instance().set('workFlowConfigured', false);
            this.view.render();
        });

        it("does note have a new work flow link", function() {
            expect(this.view.$("a.new_work_flow")).not.toExist();
        });
    });
};