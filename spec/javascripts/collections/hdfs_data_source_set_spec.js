describe("chorus.collections.HdfsDataSourceSet", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.HdfsDataSourceSet();
    });

    it("has the right url", function() {
        expect(this.collection.url()).toHaveUrlPath("/hdfs_data_sources");
    });
});
