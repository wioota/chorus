describe("chorus.models.DynamicDataset", function() {
    it("should return a chorus view when the json is for a chorus view", function() {
        var model = new chorus.models.DynamicDataset(rspecFixtures.workspaceDataset.chorusViewJson()['response']);
        expect(model).toBeA(chorus.models.ChorusView);
    });

    it("should return a workspace dataset when the json is for a workspace dataset", function() {
        var model = new chorus.models.DynamicDataset(rspecFixtures.workspaceDataset.datasetTableJson()['response']);
        expect(model).toBeA(chorus.models.WorkspaceDataset);
    });

    it("should return dataset otherwise", function() {
        var model = new chorus.models.DynamicDataset(rspecFixtures.datasetJson()['response']);
        expect(model).toBeA(chorus.models.Dataset);
    });
});