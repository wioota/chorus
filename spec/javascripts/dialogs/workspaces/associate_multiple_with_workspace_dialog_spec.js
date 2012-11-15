describe("chorus.dialogs.AssociateMultipleWithWorkspace", function() {
    beforeEach(function() {
        this.datasets = new chorus.collections.DatasetSet([
            rspecFixtures.dataset({ id: '123' }),
            rspecFixtures.dataset({ id: '456' }),
            rspecFixtures.dataset({ id: '789' })
        ]);

        this.dialog = new chorus.dialogs.AssociateMultipleWithWorkspace({
            datasets: this.datasets
        });
        this.dialog.render();
    });

    it("has the right button text", function() {
        expect(this.dialog.submitButtonTranslationKey).toBe("dataset.associate.button.other");
    });

    describe("when the workspaces are fetched and one is chosen", function() {
        beforeEach(function() {
            this.server.completeFetchAllFor(chorus.session.user().workspaces(), [
                rspecFixtures.workspace({ name: "abra", id: "11" }),
                rspecFixtures.workspace({ name: "cadabra", id: "12" })
            ]);

            this.dialog.$("li:eq(1)").click();
            this.dialog.$("button.submit").click();
        });

        it("sends a request to the 'associate dataset' API", function() {
            expect(this.server.lastCreate().url).toContain("/workspaces/12/datasets");

        });

        it("sends all of the datasets' ids", function() {
            var requestBody = decodeURIComponent(this.server.lastCreate().requestBody);
            expect(requestBody).toContain('dataset_ids[]=123');
            expect(requestBody).toContain('dataset_ids[]=456');
            expect(requestBody).toContain('dataset_ids[]=789');
        });

        it("display loading message on the button", function() {
            expect(this.dialog.$("button.submit")).toHaveSpinner();
        });

        describe("when the request succeeds", function() {
            beforeEach(function() {
                spyOn(this.dialog, "closeModal");
                spyOn(chorus, "toast");
                this.server.lastCreate().succeed();
            });

            it("displays a toast message", function() {
                expect(chorus.toast).toHaveBeenCalledWith(
                    "dataset.associate.toast.other", { count: 3, workspaceNameTarget: "cadabra" }
                );
            });

            it("closes the dialog", function() {
                expect(this.dialog.closeModal).toHaveBeenCalled();
            });

            it("fetches the associated datasets", function() {
                this.dialog.datasets.each(function(dataset) {
                    expect(dataset).toHaveBeenFetched();
                });
            });
        });
    });
});
