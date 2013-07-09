describe("chorus.dialogs.CreateFileMask", function() {
    beforeEach(function() {
        this.modalSpy = stubModals();
        this.workspace = backboneFixtures.workspace();
        this.dataSources = [backboneFixtures.hdfsDataSource(), backboneFixtures.hdfsDataSource(), backboneFixtures.hdfsDataSource()];
        this.dialog = new chorus.dialogs.CreateFileMask({ workspace: this.workspace });
        this.dialog.launchModal();
    });

    it("shows the right title", function() {
        expect(this.dialog.title).toMatchTranslation("create_file_mask_dialog.title");
    });

    it("has the create and cancel buttons", function() {
        expect(this.dialog.$("button.submit")).toContainTranslation("create_file_mask_dialog.submit");
        expect(this.dialog.$("button.cancel")).toContainTranslation("actions.cancel");
    });

    context("fetching the hadoop data sources", function() {
        it("displays a loading spinner while the data sources are fetching", function() {
            expect(this.dialog.$(".data_source .loading_text")).not.toHaveClass("hidden");
            expect(this.dialog.$(".loading_spinner").isLoading()).toBeTruthy();
        });

        context("when the fetch completes", function() {
            beforeEach(function() {
                this.server.completeFetchAllFor(this.dialog.dataSources, this.dataSources);
            });

            it("the loading spinner should be hidden", function() {
                expect(this.dialog.$(".data_source select")).not.toHaveClass("hidden");
                expect(this.dialog.$(".data_source .loading_text")).toHaveClass("hidden");
            });

            it("should have a selector populated with datasources", function() {
                expect(this.dialog.$(".data_source select option").length).toBe(4);
            });
        });

        context("when the fetch completes with no data sources", function() {
            beforeEach(function() {
                this.server.completeFetchAllFor(this.dialog.dataSources, []);
            });

            it("displays a message", function() {
                expect(this.dialog.$(".data_source")).toContainTranslation("create_file_mask_dialog.no_data_sources");
            });
        });
    });

    context("when the form is filled in", function() {
        beforeEach(function() {
            this.server.completeFetchAllFor(this.dialog.dataSources, this.dataSources);
            this.dialog.$("input.name").val("Jim Carrey").change();
            this.dialog.$(".data_source select").val(this.dataSources[2].id).change();
            this.dialog.$("input.mask").val("foo.*.bar").change().keyup();
        });

        it("enables the submit button", function() {
            expect(this.dialog.$("button.submit")).toBeEnabled();
        });

        it("disables the submit button again if the data source is unselected", function() {
            this.dialog.$(".data_source select").val("").change();
            expect(this.dialog.$("button.submit")).not.toBeEnabled();
        });

        context("submitting the form", function() {
            beforeEach(function() {
               this.dialog.$("form").submit();
            });

            it("posts with the correct values", function() {
                var params = this.server.lastCreate().params();
                expect(params).toEqual({
                    'hdfs_dataset[name]': "Jim Carrey",
                    'hdfs_dataset[data_source_id]': this.dataSources[2].id,
                    'hdfs_dataset[file_mask]': "foo.*.bar",
                    'hdfs_dataset[workspace_id]': this.workspace.id
                });
            });


            it("starts the spinner loading", function () {

            });

            context("when the save succeeds", function () {
                it("closes the modal", function() {

                });

                it("gives a toast", function() {

                });
            });

            context("when the post fails", function () {
                it("displays server errors", function () {

                });

                it("stops the spinner", function() {

                });
            });
        });
    });
});