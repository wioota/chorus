describe("chorus.collections.CsvHdfsFileSet", function () {
    beforeEach(function() {
        this.collection = new chorus.collections.CsvHdfsFileSet([
            rspecFixtures.hdfsFile().attributes,
            rspecFixtures.hdfsDir().attributes,
            rspecFixtures.hdfsFile().attributes
        ], { id: 123, hdfsDataSource: {id: 1}});
    });

    it("use the correct url", function() {
        expect(this.collection.url()).toMatchUrl("/hdfs_data_sources/1/files/?id=123", {paramsToIgnore: ["page", "per_page"]});
    });

    describe("#removeDirectories", function () {
        it("removes directories, leaving only files", function() {
            this.collection.removeDirectories();
            expect(this.collection.length).toBe(2);
        });
    });
});