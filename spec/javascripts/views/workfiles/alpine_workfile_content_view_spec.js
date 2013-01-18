describe("chorus.views.AlpineWorkfileContent", function() {
    beforeEach(function() {
        this.model = rspecFixtures.workfile.alpine();
        this.view = new chorus.views.AlpineWorkfileContent({ model: this.model });
        this.server.completeFetchFor(chorus.models.Config.instance(), rspecFixtures.config());
        this.view.render();
    });

    it("shows the image from alpine", function() {
        expect(this.view.$('img')).toHaveAttr('src', this.model.imageUrl());
    });
});