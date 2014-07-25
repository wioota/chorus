describe("chorus.views.PrimaryActionPanel", function () {
    beforeEach(function () {
        this.workspace = backboneFixtures.workspace();
        this.workspace.loaded = false;
        this.view = new chorus.views.PrimaryActionPanel({model: this.workspace});
    });

    context("before the workspace is fetched", function () {
        beforeEach(function () {
            this.view.render();
        });

        it("does not render any actions", function () {
            expect(this.view.$(".action").length).toBe(0);
        });
    });

    context("after the workspace is fetched", function () {
        context("and the user can update the workspace", function () {

            beforeEach(function () {
                this.modalSpy = stubModals();
                spyOn(this.workspace, 'canUpdate').andReturn(true);
                this.server.completeFetchFor(this.workspace);
                this.actions = ['goold_old', 'arbitrary', 'actions'];
            });

            _.each(this.actions, function (action) {
                it("contains an " + action + " link", function () {
                    expect(this.view.$("." + action)).toExist();
                });

                it(action + " has the correct translation", function () {
                    expect(this.view.$("." + action)).toContainTranslation("actions." + action);
                });
            }, this);


        });

        context("when the user can't update the workspace", function () {
            beforeEach(function () {
                spyOn(this.view.model, "canUpdate").andReturn(false);
                this.view.render();
            });

            it("does not render any buttons", function () {
                expect(this.view.$(".action").length).toBe(0);
            });
        });

        context("when the workspace is archived", function () {
            beforeEach(function () {
                this.view.model.set("archivedAt", true);
                this.view.render();
            });

            it("does not render any buttons", function () {
                expect(this.view.$(".action").length).toBe(0);
            });
        });
    });
});