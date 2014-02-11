describe("chorus.views.HelpLink", function() {
    beforeEach(function() {
        this.view = new chorus.views.HelpLink();
        this.view.render();
    });

    context("it is alpine branded", function () {
        beforeEach(function () {
            chorus.models.Config.instance().license().set('branding', 'alpine');
            this.view.render();
        });

        it("displays the alpine help link", function () {
            expect(this.view.$("a")).toHaveAttr('href', 'http://alpine.atlassian.net/wiki/display/CD/Chorus+Documentation+Home');
            expect(this.view.$("a")).toHaveAttr('target', '_blank');
        });
    });

    context("it is not alpine branded", function () {
        beforeEach(function () {
            chorus.models.Config.instance().license().set('branding', 'pivotal');
            this.view.render();
        });

        it("displays the non-alpine help link", function () {
            expect(this.view.$("a")).toHaveAttr('href', 'http://alpine.atlassian.net/wiki/display/CD/Chorus+Documentation+Home?pivotal=true');
            expect(this.view.$("a")).toHaveAttr('target', '_blank');
        });
    });
});
