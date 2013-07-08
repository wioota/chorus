describe("chorus.views.WorkspaceDatasetIndexPageButtons", function() {
    beforeEach(function() {
        this.workspace = backboneFixtures.workspace();
        this.workspace.loaded = false;
        this.view = new chorus.views.WorkspaceDatasetIndexPageButtons({model: this.workspace});
        this.qtipElement = stubQtip();
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
                expect(this.view.$("button.add_data")).toExist();
                expect(this.view.$("button.add_data")).toContainTranslation("actions.add_data");
            });

            context("clicking the add data button", function() {
                beforeEach(function() {
                    this.view.$("button.add_data").click();
                });

                it("enables the 'Import File' and 'Hadoop File Mask' button", function() {
                    expect(this.qtipElement.find(".import_file")).not.toHaveClass("disabled");
                    expect(this.qtipElement.find(".create_file_mask")).not.toHaveClass("disabled");
                });

                context("clicking on 'Import File'", function() {
                    it("launches the FileImport dialog", function() {
                        expect(this.modalSpy).not.toHaveModal(chorus.dialogs.FileImport);
                        expect(this.qtipElement.find('.import_file')).toContainTranslation('actions.import_file');
                        this.qtipElement.find('.import_file').click();
                        expect(this.modalSpy).toHaveModal(chorus.dialogs.FileImport);
                        expect(this.modalSpy.lastModal().options.workspace).toBe(this.workspace);
                    });
                });

                context("clicking on 'Hadoop File Mask'", function() {
                    it("launches the CreateFileMask dialog", function() {
                        expect(this.modalSpy).not.toHaveModal(chorus.dialogs.CreateFileMask);
                        expect(this.qtipElement.find('.create_file_mask')).toContainTranslation('actions.create_file_mask');
                        this.qtipElement.find('.create_file_mask').click();
                        expect(this.modalSpy).toHaveModal(chorus.dialogs.CreateFileMask);
                        expect(this.modalSpy.lastModal().options.workspace).toBe(this.workspace);
                    });
                });
            });

            context("when the workspace does not have a sandbox", function() {
                beforeEach(function() {
                    spyOn(this.view.model, "sandbox");
                    this.view.render();
                });

                it("hides the 'Import File' option", function() {
                    this.view.$("button.add_data").click();
                    expect(this.qtipElement.find(".import_file").closest("li")).toHaveClass("hidden");
                    expect(this.qtipElement.find(".create_file_mask").closest("li")).not.toHaveClass("hidden");
                });
            });
        });

        context("when the user can't update the workspace", function() {
            beforeEach(function() {
                spyOn(this.view.model, "canUpdate").andReturn(false);
                this.view.render();
            });

            it("does not render any buttons", function() {
                expect(this.view.$("button").length).toBe(0);
            });
        });

        context("when the workspace is archived", function() {
            beforeEach(function() {
                this.view.model.set("archivedAt", true);
                this.view.render();
            });

            it("does not render any buttons", function() {
                expect(this.view.$("button").length).toBe(0);
            });
        });
    });
});