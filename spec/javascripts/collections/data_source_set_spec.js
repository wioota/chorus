describe("chorus.collections.DataSourceSet", function() {
    it("has the correct url", function() {
        var collection = new chorus.collections.DataSourceSet();
        expect(collection.url()).toHaveUrlPath('/data_sources');
    });
});