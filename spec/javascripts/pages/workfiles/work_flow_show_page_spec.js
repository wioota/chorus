describe("chorus.pages.WorkFlowShowPage", function() {
    beforeEach(function() {
        this.page = new chorus.pages.WorkFlowShowPage('4');
        setLoggedInUser();
        this.page.render();  //normally done in the router
    });

    context("when the workfile is loaded", function() {
        beforeEach(function() {
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

    context("when the workfile is not loaded", function() {
        it("does not display garbage on Alpine", function() {
            expect(this.page.$("iframe").attr("src")).toBe("");
        });
    });

    it("routes to the login page when recieving an 'unauthorized' message", function() {
        runs(function(){
            spyOn(chorus, 'requireLogin');
            expect(chorus.requireLogin).not.toHaveBeenCalled();
            window.postMessage('unauthorized', '*');
        });
        waitsFor(function() {
            return chorus.requireLogin.callCount > 0; // times out if requireLogin never called
        });
    });
});