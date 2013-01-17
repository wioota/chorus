describe("chorus.views.AlpineWorkfileContent", function() {
    beforeEach(function() {
        this.model = rspecFixtures.workfile.image();
        this.view = new chorus.views.AlpineWorkfileContent({ model: this.model });
    });
});
