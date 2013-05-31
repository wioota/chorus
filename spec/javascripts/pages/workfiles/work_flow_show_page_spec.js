describe("chorus.pages.WorkFlowShowPage", function() {
    beforeEach(function() {
        this.page = new chorus.pages.WorkFlowShowPage('4');
        setLoggedInUser();
        this.page.render();  //normally done in the router
    });

    context("when the workfile is loaded", function() {
        beforeEach(function() {
            this.workfile = rspecFixtures.workfile.alpine({id: 4});
            this.workfile.urlParams = {connect: true};
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

        context("when receiving a 'go_to_workfile' message", function() {
            it("routes to the workflow show page", function() {
                var routerSpy;
                runs(function(){
                    routerSpy = spyOn(chorus.router, 'navigate');
                    expect(routerSpy).not.toHaveBeenCalled();
                    window.postMessage({action: 'go_to_workfile'}, '*');
                });
                waitsFor(function() {
                    return routerSpy.callCount > 0;
                });
                runs(function() {
                    expect(routerSpy).toHaveBeenCalledWith(this.workfile.showUrl());
                });
            });
        });
    });

    context("when the workfile is not loaded", function() {
        it("does not display garbage on Alpine", function() {
            expect(this.page.$("iframe").attr("src")).toBe("");
        });
    });

    context("when the workfile has errors", function () {
        context("when the errors come from the workspace", function () {
            it("does the normal thing", function () {
                spyOn(Backbone.history, "loadUrl");
                this.page.model.serverErrors = {
                    record: 'CHEESE',
                    modelData: {
                        entityType: 'workspace'
                    }
                };
                this.page.model.trigger("resourceForbidden");
                expect(Backbone.history.loadUrl).toHaveBeenCalled();
            });
        });

        context("when the errors come from the data source", function () {
            it("handles the workfile errors", function () {
                spyOn(this.page, "launchDataSourceAccountDialog");
                this.page.model.serverErrors = {
                    record: 'CHEESE',
                    modelData: {
                        entityType: 'data_source'
                    }
                };
                this.page.model.trigger("resourceForbidden");
                expect(this.page.launchDataSourceAccountDialog).toHaveBeenCalled();
            });

            it("routes to the login page when receiving an 'unauthorized' message", function() {
                runs(function(){
                    spyOn(chorus, 'requireLogin');
                    expect(chorus.requireLogin).not.toHaveBeenCalled();
                    window.postMessage({action: 'unauthorized'}, '*');
                });
                waitsFor(function() {
                    return chorus.requireLogin.callCount > 0; // times out if requireLogin never called
                });
            });
        });
    });
});