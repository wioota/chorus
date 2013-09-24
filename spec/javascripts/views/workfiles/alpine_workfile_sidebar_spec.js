describe('chorus.views.AlpineWorkfileSidebar', function(){
    beforeEach(function(){
        this.workfile = backboneFixtures.workfile.alpine();
        this.view = new chorus.views.AlpineWorkfileSidebar({model: this.workfile, showVersions: true});
        this.view.render();
    });

    it('does not render the versions', function(){
        expect(this.view.$(".version_list")).not.toExist();
    });

    it('does not render the download link', function(){
        expect(this.view.$('.actions a.download')).not.toExist();
    });

    it('does not render the update time', function(){
        expect(this.view.$('.info .updated')).not.toExist();
    });

    describe("run now", function () {
        it('shows the run now link', function () {
            expect(this.view.$('a.run_now')).toContainTranslation('work_flows.actions.run_now');
        });

        context('clicking run now', function () {
            beforeEach(function () {
                spyOn(this.view.model, 'run').andCallThrough();
                this.view.$('a.run_now').click();
                this.server.completeUpdateFor(this.view.model, {status: 'running'});
            });

            it('disables the run now link', function () {
                expect(this.view.$('span.run_now')).toHaveClass('disabled');
            });

            it('runs the workfile', function () {
                expect(this.view.model.run).toHaveBeenCalled();
            });
        });
    });
});