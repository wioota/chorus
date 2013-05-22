describe("chorus.pages.WorkFlowShowPage", function() {
    beforeEach(function() {
        this.page = new chorus.pages.WorkFlowShowPage('4');
        setLoggedInUser();
        this.page.render();

        this.workfile = rspecFixtures.workfile.alpine({id: 4});
        this.server.completeFetchFor(this.workfile);
    });

    it("fetches the workfile for the workflow", function() {
        expect(this.page.model).toBeA(chorus.models.AlpineWorkfile);
        expect(this.page.model.get("id")).toBe(4);
        expect(this.page.model).toHaveBeenFetched();
    });

    it("does not render the breadcrumbs", function() {
        expect(this.page.$(".breadcrumbs")).not.toExist();
    });

    it("has an iframe to alpine", function() {
       expect(this.page.$("iframe").attr("src")).toBe(this.workfile.iframeUrl());
    });
});