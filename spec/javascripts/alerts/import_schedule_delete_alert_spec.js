describe("chorus.alerts.ImportScheduleDelete", function() {
    beforeEach(function() {
        this.dataset = rspecFixtures.workspaceDataset.datasetTable();
        this.schedules = rspecFixtures.datasetImportScheduleSet();
        setLoggedInUser({ id: "1011" });
        this.dataset._datasetImportSchedules = this.schedules;
        this.alert = new chorus.alerts.ImportScheduleDelete({ pageModel: this.dataset });
    });

    it("does not have a redirect url", function() {
        expect(this.alert.redirectUrl).toBeUndefined();
    });

    describe("#makeModel", function() {
        it("gets the current user's account for the instance that is the current page model", function(){
            expect(this.alert.model.get("datasetId")).toBe(this.schedules.last().get("datasetId"));
        });
    });

    describe("successful deletion", function() {
        beforeEach(function() {
            spyOn(chorus, "toast");
            this.changeSpy = jasmine.createSpy("change");
            this.alert.pageModel.bind("change", this.changeSpy, this);
            this.alert.model.trigger("destroy", this.alert.model);
        });

        it("displays a toast message", function() {
            expect(chorus.toast).toHaveBeenCalledWith("import.schedule.delete.toast", undefined);
            expect(chorus.toast.callCount).toBe(1);
        });
    });
});
