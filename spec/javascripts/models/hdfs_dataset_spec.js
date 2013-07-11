describe("chorus.models.HdfsDataset", function() {
    beforeEach(function () {
        this.model = backboneFixtures.workspaceDataset.hdfsDataset();
    });

    describe('dataSource', function () {
        it("is not null", function () {
            expect(this.model.dataSource()).toBeA(chorus.models.HdfsDataSource);
        });
    });

    describe("#urlTemplate", function() {
        context("when it is a post", function() {
            it("returns the correct url", function () {
                expect(this.model.url({ method: 'create' })).toMatchUrl("/hdfs_datasets");
            });
        });

        context("when it is anything else", function() {
            beforeEach(function () {
                this.model.set("id", 1234);
            });

            it("returns the correct url", function () {
                expect(this.model.url({ method: 'read' })).toMatchUrl("/datasets/1234");
            });
        });
    });
});