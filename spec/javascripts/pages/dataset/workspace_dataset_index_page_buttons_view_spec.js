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
                    expect(this.qtipElement.find(".create_hdfs_dataset")).not.toHaveClass("disabled");
                    expect(this.qtipElement.find(".browse_data_sources")).not.toHaveClass("disabled");
                });

                context("clicking on 'Import File'", function() {
                    it("launches the WorkspaceFileImport dialog", function() {
                        expect(this.modalSpy).not.toHaveModal(chorus.dialogs.WorkspaceFileImport);
                        expect(this.qtipElement.find('.import_file')).toContainTranslation('actions.import_file');
                        this.qtipElement.find('.import_file').click();
                        expect(this.modalSpy).toHaveModal(chorus.dialogs.WorkspaceFileImport);
                        expect(this.modalSpy.lastModal().options.workspace).toBe(this.workspace);
                    });
                });

                context("clicking on 'Hadoop File Mask'", function() {
                    it("launches the CreateHdfsDataset dialog", function() {
                        expect(this.modalSpy).not.toHaveModal(chorus.dialogs.CreateHdfsDataset);
                        expect(this.qtipElement.find('.create_hdfs_dataset')).toContainTranslation('actions.create_hdfs_dataset');
                        this.qtipElement.find('.create_hdfs_dataset').click();
                        expect(this.modalSpy).toHaveModal(chorus.dialogs.CreateHdfsDataset);
                        expect(this.modalSpy.lastModal().options.workspace).toBe(this.workspace);
                    });
                });

                context("clicking on 'Browse Data Sources'", function () {
                    beforeEach(function () {
                        spyOn(chorus.router, "navigate");
                        this.data_source_url = "/data_sources";
                        this.qtipElement.find('.browse_data_sources').click();
                    });

                    it("navigates to the data sources index page", function () {
                        expect(chorus.router.navigate).toHaveBeenCalledWith(this.data_source_url);
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
                    expect(this.qtipElement.find(".create_hdfs_dataset").closest("li")).not.toHaveClass("hidden");
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
