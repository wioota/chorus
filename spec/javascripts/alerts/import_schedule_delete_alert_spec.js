describe("chorus.alerts.ImportScheduleDelete", function() {
    beforeEach(function() {
        this.dataset = backboneFixtures.workspaceDataset.datasetTable();
        this.schedules = backboneFixtures.datasetImportScheduleSet();
        setLoggedInUser({ id: "1011" });
        this.dataset._datasetImportSchedules = this.schedules;
        this.alert = new chorus.alerts.ImportScheduleDelete({ model: this.dataset.importSchedule() });
    });

    it("does not have a redirect url", function() {
        expect(this.alert.redirectUrl).toBeUndefined();
    });

    describe("#makeModel", function() {
        it("gets the user account for that data source", function(){
            expect(this.alert.model.get("datasetId")).toBe(this.schedules.last().get("datasetId"));
        });
    });

    describe("successful deletion", function() {
        beforeEach(function() {
            spyOn(chorus, "toast");
            this.changeSpy = jasmine.createSpy("change");
            this.alert.model.trigger("destroy", this.alert.model);
        });

        it("displays a toast message", function() {
            expect(chorus.toast).toHaveBeenCalledWith("import.schedule.delete.toast", undefined);
            expect(chorus.toast.callCount).toBe(1);
        });
    });
});
