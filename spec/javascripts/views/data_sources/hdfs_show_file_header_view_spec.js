describe("chorus.views.HdfsShowFileHeader", function() {
    beforeEach(function() {
        this.hdfsEntry = backboneFixtures.hdfsFile();
        this.view = new chorus.views.HdfsShowFileHeader({model: this.hdfsEntry});
    });

    it("shows a tag box", function() {
        this.view.render();
        expect(this.view.$('.tag_box')).toExist();
    });
});
