describe("chorus.views.AlpineWorkfileContentDetails", function() {
    beforeEach(function() {
        this.model = rspecFixtures.workfile.alpine();
        this.view = new chorus.views.AlpineWorkfileContentDetails({ model: this.model });
        this.server.completeFetchFor(chorus.models.Config.instance(), rspecFixtures.config());
        this.view.render();
    });

    describe("render", function() {
        it("shows the 'Run File' button", function() {
            expect(this.view.$('a.button.run_file')).toContainTranslation('workfile.content_details.run_file');
        });

        it("links the 'Run File' button to the Alpine page", function() {
            var url = URI('/AlpineIlluminator/alpine/result/runflow.jsp?')
                  .addQuery("flowFilePath", "/tmp/run_file_test.afm");
            url.addQuery('actions[create_workfile_insight]',
                          'http://' + window.location.host + '/notes/');
            expect(this.view.$('a.button.run_file')).toHaveHref(this.model.runUrl());
            expect(this.view.$('a.button.run_file')).toHaveAttr('target', 'alpine');
        });
    });
});
