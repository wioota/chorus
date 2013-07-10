describe("chorus.models.HdfsDataset", function() {
    beforeEach(function () {
        this.dataset = backboneFixtures.workspaceDataset.hdfsDataset();
    });

    describe('dataSource', function () {
        it("is not null", function () {
            expect(this.dataset.dataSource()).toBeA(chorus.models.HdfsDataSource);
        });
    });
});