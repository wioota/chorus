describe("chorus.alerts.DatasetDisassociateMultiple", function() {
    beforeEach(function() {
        this.collection = backboneFixtures.workspace().datasets();
        this.alert = new chorus.alerts.DatasetDisassociateMultiple({ collection : this.collection });
        stubModals();
        this.alert.launchModal();
    });

    describe("when the alert closes", function() {
        beforeEach(function() {
            this.alert.render();
            this.alert.$("button.cancel").click();
            spyOn(chorus.router, "navigate");
            spyOn(chorus, 'toast');
        });

        it("unbinds event handlers on the model", function() {
            this.collection.trigger("destroy");
            expect(chorus.toast).not.toHaveBeenCalled();
            expect(chorus.router.navigate).not.toHaveBeenCalled();
        });
    });

    describe("when the dataset deletion is successful", function() {
        beforeEach(function() {
            spyOn(chorus.router, "navigate");
            spyOn(chorus, 'toast');
            this.collection.destroy();
            this.server.lastDestroy().succeed();
        });

        it("displays a toast message", function() {
            expect(chorus.toast).toHaveBeenCalledWith("dataset_delete.many.toast", {count: this.collection.length});
        });

        it("navigates to the dataset list page", function() {
            expect(chorus.router.navigate).toHaveBeenCalledWith("#/workspaces/" + this.collection.attributes.workspaceId + "/datasets");
        });
    });
});
