describe('chorus.views.AlpineWorkfileSidebar', function(){
    beforeEach(function(){
        this.workfile = rspecFixtures.workfile.alpine();
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
});