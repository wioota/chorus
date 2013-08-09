describe("chorus.pages.StyleGuidePage", function() {
    beforeEach(function () {
        this.page = new chorus.pages.StyleGuidePage();
        this.page.render();
    });

    it("has a SiteElementsView", function () {
        expect(this.page.mainContent.content).toBeA(chorus.pages.StyleGuidePage.SiteElementsView);
    });

});