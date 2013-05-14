describe("chorus.views.WorkfileIndexPageButtons", function() {
    beforeEach(function() {
        this.workspace = rspecFixtures.workspace();
        this.workspace.loaded = false;
        this.view = new chorus.views.WorkfileIndexPageButtons({model: this.workspace});
    });

    context("before the workspace is fetched", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("does not render any buttons", function() {
            expect(this.view.$("button").length).toBe(0);
        });
    });

    context("after the workspace is fetched", function() {
        context("and the user can update the workspace", function() {
            beforeEach(function() {
                this.modalSpy = stubModals();
                spyOn(this.workspace, 'canUpdate').andReturn(true);
                this.server.completeFetchFor(this.workspace);
            });

            it("renders buttons", function() {
                expect(this.view.$("button.import_workfile")).toExist();
                expect(this.view.$("button.new_workfile")).toExist();
            });

            context("clicking the import workfile button", function() {
                beforeEach(function() {
                    this.view.$("button.import_workfile").click();
                });

                it("launches the WorkfilesImport dialog", function() {
                    expect(this.modalSpy).toHaveModal(chorus.dialogs.WorkfilesImport);
                    expect(this.modalSpy.lastModal().options.workspaceId).toBe(this.workspace.id);
                });
            });

            context("clicking the create sql workfile button", function() {
                beforeEach(function() {
                    this.view.$("button.new_workfile").click();
                });

                it("launches the WorkfilesSqlNew dialog", function() {
                    expect(this.modalSpy).toHaveModal(chorus.dialogs.WorkfilesSqlNew);
                    expect(this.modalSpy.lastModal().options.workspaceId).toBe(this.workspace.id);
                });
            });
        });

        context("and the user cannot update the workspace", function() {
            beforeEach(function() {
                spyOn(this.workspace, 'canUpdate').andReturn(false);
                this.server.completeFetchFor(this.workspace);
            });

            it("does not render buttons", function() {
                expect(this.view.$("button").length).toBe(0);
            });
        });

        context("and the workspace is archived", function() {
            beforeEach(function() {
                this.workspace.set({archivedAt: "2012-05-08 21:40:14"});
                this.server.completeFetchFor(this.workspace);
            });

            it("does not render buttons", function() {
                expect(this.view.$("button").length).toBe(0);
            });
        });
    });
});
