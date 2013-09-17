describe("chorus.views.ProjectStatusView", function() {
    beforeEach(function() {
        this.modalSpy = stubModals();
        this.model = backboneFixtures.workspace({ id : 4 });
        this.model.fetch();
        this.view = new chorus.views.ProjectStatus({ model : this.model });
        this.view.render();
    });

    itBehavesLike.aDialogLauncher("a.edit_project_status", chorus.dialogs.EditProjectStatus);

    describe("project status", function () {
        describe("reason", function () {
            it("displays in tooltip", function () {
                var tooltip = this.view.$('.status-reason').attr('oldtitle');
                expect(tooltip).toEqual(this.model.get('projectStatusReason'));
            });
        });

        it("is set as a class on the edit link, so it can be colored", function () {
            expect(this.view.$('a.edit_project_status')).toHaveClass(this.model.get('projectStatus'));
        });
    });

    describe("milestones progress", function () {
        it("shows milestone progress as the width of progress bar", function () {
            expect(this.view.$('.progress').width()).toBe(this.model.milestoneProgress());
        });

        it("displays the ratio of milestones completed to milestones", function () {
            var completed = this.model.get('milestoneCompletedCount');
            var total = this.model.get('milestoneCount');

            expect(this.view.$('.ratio')).toContainText(completed + ' / ' + total);
        });
    });
});
