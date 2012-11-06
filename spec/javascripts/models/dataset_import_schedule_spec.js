describe('chorus.models.DatasetImportSchedule', function() {
    beforeEach(function() {
        this.model = rspecFixtures.datasetImportScheduleSet().at(0);
        this.model.set({ workspaceId: "999", datasetId: "23456"});
    });

    it("has the correct URL", function () {
        expect(this.model.url()).toContain("/workspaces/999/datasets/23456/import_schedules");
    });
});